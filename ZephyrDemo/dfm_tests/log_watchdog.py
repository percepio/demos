"""Watch one log file for prolonged size inactivity."""

from __future__ import annotations

import _thread
import argparse
from pathlib import Path
import subprocess
import sys
import threading
import time
from typing import Callable, Sequence


CHECK_INTERVAL_SECONDS = 60
MAX_UNCHANGED_CHECKS = 15
WATCHDOG_TIMEOUT_EXIT_CODE = 124


def start_watchdog(
    log_path: Path,
) -> tuple[subprocess.Popen[str], threading.Event, threading.Thread]:
    """Start this file as a watcher process and relay a timeout to main."""

    process = subprocess.Popen(
        [sys.executable, str(Path(__file__).resolve()), str(log_path)],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        text=True,
    )
    expired = threading.Event()

    def relay_timeout() -> None:
        if process.wait() == WATCHDOG_TIMEOUT_EXIT_CODE:
            expired.set()
            _thread.interrupt_main()

    waiter = threading.Thread(target=relay_timeout, daemon=True)
    waiter.start()
    return process, expired, waiter


def stop_watchdog(
    process: subprocess.Popen[str], waiter: threading.Thread
) -> None:
    if process.poll() is None:
        process.terminate()
        try:
            process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait()
    waiter.join(timeout=1)


def log_size(path: Path) -> int:
    try:
        return path.stat().st_size
    except OSError:
        return -1


def watch_log(
    log_path: Path,
    *,
    check_interval_seconds: float = CHECK_INTERVAL_SECONDS,
    max_unchanged_checks: int = MAX_UNCHANGED_CHECKS,
    sleep: Callable[[float], None] = time.sleep,
) -> int:
    """Return 124 after 15 unchanged one-minute size checks."""

    previous_size = log_size(log_path)
    unchanged_checks = 0
    while True:
        sleep(check_interval_seconds)
        current_size = log_size(log_path)
        if current_size != previous_size:
            previous_size = current_size
            unchanged_checks = 0
            continue
        unchanged_checks += 1
        if unchanged_checks >= max_unchanged_checks:
            return WATCHDOG_TIMEOUT_EXIT_CODE


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("log_path", type=Path)
    args = parser.parse_args(argv)
    return watch_log(args.log_path)


if __name__ == "__main__":
    raise SystemExit(main())
