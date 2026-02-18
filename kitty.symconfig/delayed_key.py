import sys
import time
import re
import shutil
import datetime
import argparse
from typing import List
from kitty.boss import Boss

# --- Parsing Logic ---

def parse_time_arg(arg: str) -> float:
    arg = arg.strip().lower()

    # 1. Check for Absolute Time (HH:MM)
    if ':' in arg:
        try:
            now = datetime.datetime.now()
            for fmt in ("%H:%M:%S", "%H:%M"):
                try:
                    parsed = datetime.datetime.strptime(arg, fmt)
                    target = now.replace(hour=parsed.hour, minute=parsed.minute, second=parsed.second, microsecond=0)
                    if target <= now:
                        target += datetime.timedelta(days=1)
                    diff = (target - now).total_seconds()
                    return diff if diff > 0 else 0
                except ValueError:
                    continue
            raise ValueError
        except Exception:
            raise ValueError("Invalid time format")

    # 2. Check for Composite Duration (e.g., 1h30m)
    matches = re.findall(r'(\d+(?:\.\d+)?)([hms])', arg)
    if matches:
        total_seconds = 0.0
        for val, unit in matches:
            v = float(val)
            if unit == 'h': total_seconds += v * 3600
            elif unit == 'm': total_seconds += v * 60
            elif unit == 's': total_seconds += v
        return total_seconds

    # 3. Fallback: Raw number implies seconds
    try:
        return float(arg)
    except ValueError:
        raise ValueError("Invalid time format")

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
    print("  \033[2mExamples: 30s, 1m, 1h30m, 14:00\033[0m\n")

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

    lines = [
        f"\033[1;36mDELAYED KEY ENTRY\033[0m",
        "",
        f"Sequence: {cmd_preview}",
        "",
        f"Firing in: \033[1;37m{time_str}\033[0m",
        f"\033[36m{bar}\033[0m"
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
    parser.add_argument("-t", "--time", help="Time to wait (e.g. 10s, 1m)")

    try:
        parsed_args = parser.parse_args(args[1:])
    except SystemExit:
        return "ERROR:INVALID_ARGS"

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
        delay_seconds = parse_time_arg(time_str)
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
        sys.stdout.write("\033[?25h")
        sys.stdout.flush()

def handle_result(args: List[str], result: str, target_window_id: int, boss: Boss) -> None:
    if not result or result == "CANCELLED" or result.startswith("ERROR"):
        return

    window = boss.window_id_map.get(target_window_id)
    if window:
        window.write_to_child(result)
