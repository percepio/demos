"""Collapse repeated CRs before LF in the completed QEMU text session log.

Zephyr's console and QEMU's Windows text logging can both expand newlines.
Run only after QEMU exits; leave all other bytes (including DFM data) intact.
"""

import argparse
from pathlib import Path
import re


def normalize_log(path: Path) -> None:
    try:
        original = path.read_bytes()
    except FileNotFoundError:
        # A failed debug launch may never have opened its log.
        return
    normalized = re.sub(rb"\r+\n", b"\r\n", original)
    if normalized != original:
        path.write_bytes(normalized)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("log", type=Path)
    normalize_log(parser.parse_args().log)
