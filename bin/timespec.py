#!/usr/bin/env python3
# Shared time-spec parsing for `rrule` and kitty's delayed_key.py kitten.
#
# A time spec is one of:
#   - a provider name ("claude", "codex"): the delay until that provider's
#     next usable limit reset, per the CodexBar CLI
#   - a clock time ("18:30", "5:31pm"): the delay until that time next occurs
#   - a duration ("1w2d", "5h45m", "2h34", "90"): a duration in seconds
#     (days are 24 hours; weeks are 7 days)
#
# This module has no third-party or kitty dependencies so that both consumers
# can import it. Run it directly to execute the tests:
#
#   python3 bin/timespec.py

import datetime
import json
import re
import shutil
import subprocess
import time
from typing import Optional

CODEXBAR_PROVIDERS = ("claude", "codex")
CODEXBAR_TIMEOUT_SECONDS = 30
# Fire slightly after the reported reset so clock skew or a provider rounding
# its reset time down can't land us before the limit actually resets.
CODEXBAR_RESET_BUFFER_SECONDS = 60


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
    return target - now + CODEXBAR_RESET_BUFFER_SECONDS


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
    # unitless value uses the next smaller unit (w -> d -> h -> m -> s):
    # 2h34 means 2h34m, and 2m34 means 2m34s.
    matches = list(re.finditer(r'(\d+(?:\.\d+)?)\s*([wdhms])', arg))
    if matches:
        total_seconds = 0.0
        end = 0
        factors = {'w': 604800, 'd': 86400, 'h': 3600, 'm': 60, 's': 1}
        for match in matches:
            if arg[end:match.start()].strip():
                raise ValueError("Invalid time format")
            total_seconds += float(match.group(1)) * factors[match.group(2)]
            end = match.end()

        trailing = arg[end:].strip()
        if trailing:
            last_unit = matches[-1].group(2)
            smaller_units = {'w': 'd', 'd': 'h', 'h': 'm', 'm': 's'}
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
        "1d": 86400,
        "1w": 604800,
        "1w2d3h4m5s": 788645,
        "1.5d": 129600,
        "0.5w": 302400,
        " 1W 2D ": 777600,
        "1d2": 93600,
        "1w2": 777600,
        "5:31pm": 19860,
        "5:31 pm": 19860,
        "5:31:15pm": 19875,
        "5:31am": 63060,
        "12:00am": 43200,
        "12:00pm": 86400,
        "17:31": 19860,
    }
    invalid_cases = (
        "1hwat", "2h34wat", "1s2", "5:31xm",
        "1dwat", "1w2wat", "1d-2h", "w", "1d2w3wat",
    )

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
    # Expected values include CODEXBAR_RESET_BUFFER_SECONDS.
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
            3660,
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
            7260,
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
            10860,
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


if __name__ == "__main__":
    run_tests()
