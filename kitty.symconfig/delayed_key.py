# Run the embedded time-parser tests through Kitty's kitten action. For
# example, temporarily add this mapping to kitty.conf, reload it, and press
# the mapped key:
#
#   map ctrl+shift+f12 kitten delayed_key.py --test
#
# The suite covers valid durations and clock times as well as malformed input.
# It uses a fixed current time so absolute-time results are deterministic. Run
# it through Kitty rather than directly with Python, since this script imports
# Kitty's Python APIs.

import argparse
import datetime
import json
import re
import shutil
import subprocess
import sys
import time
from typing import List, Optional
from kitty.boss import Boss

# --- Parsing Logic ---

CODEXBAR_PROVIDERS = ("claude", "codex")
CODEXBAR_TIMEOUT_SECONDS = 30


def fetch_codexbar_usage(provider: str) -> dict:
    codexbar = shutil.which("codexbar")
    if codexbar is None:
        for path in (
            "/opt/homebrew/bin/codexbar",
            "/usr/local/bin/codexbar",
        ):
            if shutil.which(path):
                codexbar = path
                break
    if codexbar is None:
        raise ValueError("CodexBar CLI is not installed")

    try:
        result = subprocess.run(
            [
                codexbar,
                "usage",
                "--provider",
                provider,
                "--format",
                "json",
                "--no-color",
            ],
            capture_output=True,
            text=True,
            timeout=CODEXBAR_TIMEOUT_SECONDS,
        )
    except subprocess.TimeoutExpired:
        raise ValueError("CodexBar usage lookup timed out")
    except OSError as error:
        raise ValueError("Could not run CodexBar CLI") from error

    if result.returncode != 0:
        raise ValueError("CodexBar usage lookup failed")

    try:
        records = json.loads(result.stdout)
    except json.JSONDecodeError as error:
        raise ValueError("CodexBar returned invalid JSON") from error

    if isinstance(records, dict):
        records = [records]
    if not isinstance(records, list):
        raise ValueError("CodexBar returned an unexpected response")

    record = next(
        (
            item
            for item in records
            if isinstance(item, dict) and item.get("provider") == provider
        ),
        None,
    )
    if record is None:
        raise ValueError(f"CodexBar returned no {provider} usage")

    error = record.get("error")
    if isinstance(error, dict):
        message = error.get("message")
        if isinstance(message, str) and message:
            raise ValueError(message)
        raise ValueError(f"CodexBar could not fetch {provider} usage")

    usage = record.get("usage")
    if not isinstance(usage, dict):
        raise ValueError(f"CodexBar returned no {provider} usage")
    return usage


def parse_reset_timestamp(value) -> Optional[float]:
    if isinstance(value, bool):
        return None
    if isinstance(value, (int, float)):
        return float(value)
    if not isinstance(value, str):
        return None

    try:
        parsed = datetime.datetime.fromisoformat(
            value.replace("Z", "+00:00")
        )
    except ValueError:
        return None
    if parsed.tzinfo is None:
        return None
    return parsed.timestamp()


def select_reset_delay(usage: dict, now: Optional[float] = None) -> float:
    if now is None:
        now = time.time()

    windows = []
    for name in ("primary", "secondary", "tertiary"):
        window = usage.get(name)
        if not isinstance(window, dict):
            continue

        resets_at = parse_reset_timestamp(window.get("resetsAt"))
        if resets_at is None or resets_at <= now:
            continue

        used_percent = window.get("usedPercent")
        exhausted = (
            isinstance(used_percent, (int, float))
            and not isinstance(used_percent, bool)
            and used_percent >= 100
        )
        windows.append((exhausted, resets_at))

    if not windows:
        raise ValueError("CodexBar returned no future reset time")

    exhausted_resets = [
        resets_at for exhausted, resets_at in windows if exhausted
    ]
    if exhausted_resets:
        # If more than one limit is exhausted, the provider is usable only
        # after all of those windows have reset.
        target = max(exhausted_resets)
    else:
        target = min(resets_at for _, resets_at in windows)
    return target - now


def resolve_time_arg(
    arg: str,
    now: Optional[datetime.datetime] = None,
) -> float:
    provider = arg.strip().lower()
    if provider not in CODEXBAR_PROVIDERS:
        return parse_time_arg(arg, now=now)

    usage = fetch_codexbar_usage(provider)
    now_timestamp = now.timestamp() if now is not None else None
    return select_reset_delay(usage, now=now_timestamp)

def parse_time_arg(
    arg: str,
    now: Optional[datetime.datetime] = None,
) -> float:
    arg = arg.strip().lower()

    # 1. Check for absolute clock time.
    if ':' in arg:
        # Normalize both "5:31pm" and "5:31 pm" for strptime.
        clock_arg = re.sub(r'\s*([ap]m)$', r' \1', arg)
        formats = ("%I:%M:%S %p", "%I:%M %p", "%H:%M:%S", "%H:%M")
        for fmt in formats:
            try:
                parsed = datetime.datetime.strptime(clock_arg, fmt)
            except ValueError:
                continue

            if now is None:
                now = datetime.datetime.now()
            target = now.replace(
                hour=parsed.hour,
                minute=parsed.minute,
                second=parsed.second,
                microsecond=0,
            )
            if target <= now:
                target += datetime.timedelta(days=1)
            return (target - now).total_seconds()

        raise ValueError("Invalid time format")

    # 2. Check for a composite duration (e.g., 1h30m). A trailing
    # unitless value uses the next smaller unit: 2h34 means 2h34m, and
    # 2m34 means 2m34s.
    matches = list(re.finditer(r'(\d+(?:\.\d+)?)\s*([hms])', arg))
    if matches:
        total_seconds = 0.0
        end = 0
        factors = {'h': 3600, 'm': 60, 's': 1}
        for match in matches:
            if arg[end:match.start()].strip():
                raise ValueError("Invalid time format")
            total_seconds += float(match.group(1)) * factors[match.group(2)]
            end = match.end()

        trailing = arg[end:].strip()
        if trailing:
            last_unit = matches[-1].group(2)
            smaller_units = {'h': 'm', 'm': 's'}
            if (
                last_unit not in smaller_units
                or not re.fullmatch(r'\d+(?:\.\d+)?', trailing)
            ):
                raise ValueError("Invalid time format")
            total_seconds += float(trailing) * factors[smaller_units[last_unit]]
        return total_seconds

    # 3. Fallback: Raw number implies seconds
    try:
        return float(arg)
    except ValueError:
        raise ValueError("Invalid time format")

def run_tests() -> None:
    now = datetime.datetime(2026, 8, 1, 12, 0, 0)
    valid_cases = {
        "45": 45,
        "30s": 30,
        "1m": 60,
        "1h30m": 5400,
        "2h34": 9240,
        "2h34m": 9240,
        "2m34": 154,
        "1h 30m": 5400,
        "5:31pm": 19860,
        "5:31 pm": 19860,
        "5:31:15pm": 19875,
        "5:31am": 63060,
        "12:00am": 43200,
        "12:00pm": 86400,
        "17:31": 19860,
    }
    invalid_cases = ("1hwat", "2h34wat", "1s2", "5:31xm")

    for value, expected in valid_cases.items():
        actual = parse_time_arg(value, now=now)
        if actual != expected:
            raise AssertionError(
                f"{value!r}: expected {expected}s, got {actual}s"
            )

    for value in invalid_cases:
        try:
            parse_time_arg(value, now=now)
        except ValueError:
            continue
        raise AssertionError(f"{value!r}: expected an invalid time error")

    reset_now = datetime.datetime(
        2026,
        8,
        1,
        12,
        0,
        tzinfo=datetime.timezone.utc,
    ).timestamp()
    reset_cases = (
        (
            {
                "primary": {
                    "usedPercent": 50,
                    "resetsAt": "2026-08-01T13:00:00Z",
                },
                "secondary": {
                    "usedPercent": 25,
                    "resetsAt": "2026-08-01T14:00:00Z",
                },
            },
            3600,
        ),
        (
            {
                "primary": {
                    "usedPercent": 100,
                    "resetsAt": "2026-08-01T13:00:00Z",
                },
                "secondary": {
                    "usedPercent": 100,
                    "resetsAt": "2026-08-01T14:00:00Z",
                },
            },
            7200,
        ),
        (
            {
                "primary": {
                    "usedPercent": 100,
                    "resetsAt": "2026-08-01T11:00:00Z",
                },
                "secondary": {
                    "usedPercent": 40,
                    "resetsAt": "2026-08-01T15:00:00Z",
                },
            },
            10800,
        ),
    )
    for usage, expected in reset_cases:
        actual = select_reset_delay(usage, now=reset_now)
        if actual != expected:
            raise AssertionError(
                f"reset case: expected {expected}s, got {actual}s"
            )

    try:
        select_reset_delay({"primary": None}, now=reset_now)
    except ValueError:
        pass
    else:
        raise AssertionError("missing reset: expected an invalid time error")

    print(
        f"Passed {len(valid_cases)} valid and "
        f"{len(invalid_cases)} invalid time parsing tests, plus "
        f"{len(reset_cases) + 1} CodexBar reset tests."
    )

def parse_key_sequence(text: str) -> str:
    def hex_repl(match):
        try:
            return chr(int(match.group(1), 16))
        except ValueError:
            return match.group(0)
    text = re.sub(r'\\x([0-9a-fA-F]{2})', hex_repl, text)

    replacements = {
        r'\e': '\x1b', r'\r': '\r', r'\n': '\n',
        r'\t': '\t',   r'\b': '\b', r'\\': '\\'
    }
    for k, v in replacements.items():
        text = text.replace(k, v)
    return text

def readable_representation(text: str) -> str:
    mapping = {
        '\r': ' [RET] ', '\n': ' [LF] ',
        '\x1b': ' [ESC] ', '\t': ' [TAB] ', ' ': ' [SPC] '
    }
    out = ""
    for char in text:
        if char in mapping:
            out += f"\033[1;33m{mapping[char]}\033[0m"
        elif char.isprintable():
            out += char
        else:
            out += f"\\x{ord(char):02x}"
    return out

# --- UI Logic ---

def set_terminal_title(title: str) -> None:
    # OSC 2 sets the window title; kitty derives the tab title from this when
    # the window doesn't have an explicitly-set tab title.
    sys.stdout.write(f"\033]2;{title}\007")

def format_countdown(seconds: float) -> str:
    if seconds < 10:
        return f"{seconds:.1f}s"

    seconds_int = int(round(seconds))
    if seconds_int < 60:
        return f"{seconds_int}s"

    minutes, secs = divmod(seconds_int, 60)

    # If less than 10 minutes, show seconds
    if seconds_int < 600:
        return f"{minutes}m {secs}s"

    hours, minutes = divmod(minutes, 60)
    if hours > 0:
        return f"{hours}h{minutes}m"
    else:
        return f"{minutes}m"

def prompt_for_time() -> str:
    # Initial clear
    sys.stdout.write("\033[2J\033[H\033[?25h")
    print("\n\033[1;36m  DELAYED KEY ENTRY\033[0m")
    print("  ─────────────────")
    print("  Enter delay time.")
    print(
        "  \033[2mExamples: 30s, 1m, 1h30, 14:00, 5:31pm, "
        "claude, codex\033[0m\n"
    )

    while True:
        try:
            sys.stdout.write("\033[1;32m  ⏱  Time > \033[0m")
            sys.stdout.flush()
            val = input().strip()
            if val:
                return val
        except KeyboardInterrupt:
            return None

def draw_ui(remaining: float, total: float, cmd_preview: str, finish_time_str: str = None, force_clear: bool = False):
    cols, rows = shutil.get_terminal_size()

    # If a resize happened (force_clear is True), we wipe the screen clean
    # so we don't leave artifacts from the previous centering.
    if force_clear:
        sys.stdout.write("\033[2J\033[H")

    progress = 1.0 - (remaining / total) if total > 0 else 1.0
    bar_width = min(40, cols - 4) # Ensure bar fits in narrow terminals
    filled = int(bar_width * progress)
    bar = "█" * filled + "░" * (bar_width - filled)

    time_str = format_countdown(remaining)

    set_terminal_title(f"delayed key — {time_str}")

    lines = [
        "\033[1;36mDELAYED KEY ENTRY\033[0m",
        "",
        f"Sequence: {cmd_preview}",
        "",
        f"Firing in: \033[1;37m{time_str}\033[0m",
        f"\033[36m{bar}\033[0m",
    ]

    if finish_time_str:
        lines.append(f"\033[2mAction at: {finish_time_str}\033[0m")
    else:
        lines.append("")

    lines.append("")
    lines.append("\033[2mPress Ctrl+C to Cancel\033[0m")

    # Vertical Centering
    start_row = max(1, (rows - len(lines)) // 2)

    for i, line in enumerate(lines):
        # Calculate horizontal center
        clean_line = re.sub(r'\033\[[0-9;]*m', '', line)
        col_offset = max(1, (cols - len(clean_line)) // 2)

        # Clear the entire row first. Clearing only from the centered column
        # can leave stale characters when shorter/later text shifts right.
        row = start_row + i
        sys.stdout.write(f"\033[{row};1H\033[2K\033[{row};{col_offset}H{line}")

    sys.stdout.flush()

# --- Main Execution ---

def main(args: List[str]) -> str:
    parser = argparse.ArgumentParser(description="Delayed Key Entry Kitten")
    parser.add_argument("keys", nargs="*", help="Keys to send (default: \\r)")
    parser.add_argument(
        "-t",
        "--time",
        help="Time to wait (e.g. 10s, 1m, claude, codex)",
    )
    parser.add_argument(
        "--test",
        action="store_true",
        help="run embedded time parsing tests",
    )

    try:
        parsed_args = parser.parse_args(args[1:])
    except SystemExit:
        return "ERROR:INVALID_ARGS"

    if parsed_args.test:
        run_tests()
        return "CANCELLED"

    if parsed_args.keys:
        raw_input = " ".join(parsed_args.keys)
    else:
        raw_input = r"\r"

    payload = parse_key_sequence(raw_input)
    preview = readable_representation(payload)

    time_str = parsed_args.time

    if not time_str:
        time_str = prompt_for_time()
        if not time_str:
            return "CANCELLED"

    try:
        delay_seconds = resolve_time_arg(time_str)
    except ValueError:
        return "ERROR:INVALID_TIME"

    now = datetime.datetime.now()
    finish_dt = now + datetime.timedelta(seconds=delay_seconds)
    finish_time_str = None
    if delay_seconds > 60:
        finish_time_str = finish_dt.strftime("%H:%M:%S")

    # Clear screen initially
    sys.stdout.write("\033[2J\033[H\033[?25l")
    sys.stdout.flush()

    last_size = shutil.get_terminal_size()

    try:
        start_time = time.time()
        while True:
            elapsed = time.time() - start_time
            remaining = delay_seconds - elapsed

            if remaining <= 0:
                break

            # Check for resize
            current_size = shutil.get_terminal_size()
            resized = (current_size != last_size)
            if resized:
                last_size = current_size

            draw_ui(remaining, delay_seconds, preview, finish_time_str, force_clear=resized)
            time.sleep(0.05)

        return payload

    except KeyboardInterrupt:
        return "CANCELLED"

    finally:
        # Reset title so the underlying window's next prompt redraw can claim it.
        sys.stdout.write("\033]2;\007")
        sys.stdout.write("\033[?25h")
        sys.stdout.flush()

def handle_result(args: List[str], result: str, target_window_id: int, boss: Boss) -> None:
    if not result or result == "CANCELLED" or result.startswith("ERROR"):
        return

    window = boss.window_id_map.get(target_window_id)
    if window:
        window.write_to_child(result)
