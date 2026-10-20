"""Fail if the tree looks like it contains a private key.

A simple grep is enough for M16 (docs/prd/16-security-and-privacy.md).
CI runs this on the checkout. The fixture under tool/testdata/ is excluded
so the scanner can be tested without failing the job.

Usage: python tool/check_secrets.py [repo_root]
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

PRIVATE_KEY = re.compile(r"-----BEGIN [A-Z0-9 ]*PRIVATE KEY-----")

SKIP_DIR_NAMES = {".git", "build", ".dart_tool", "__pycache__", "node_modules"}
SKIP_PATH_PARTS = ("tool/testdata",)


def should_skip(path: Path, root: Path) -> bool:
    relative = path.relative_to(root).as_posix()
    if any(part in relative for part in SKIP_PATH_PARTS):
        return True
    return any(part in SKIP_DIR_NAMES for part in path.parts)


def findings(root: Path) -> list[str]:
    hits: list[str] = []
    for path in root.rglob("*"):
        if not path.is_file() or should_skip(path, root):
            continue
        try:
            text = path.read_text(encoding="utf-8")
        except (OSError, UnicodeDecodeError):
            continue
        if PRIVATE_KEY.search(text):
            hits.append(path.relative_to(root).as_posix())
    return hits


def scan_file(path: Path) -> bool:
    """True when this one file looks like a private key. Used by the fixture test."""
    try:
        return PRIVATE_KEY.search(path.read_text(encoding="utf-8")) is not None
    except (OSError, UnicodeDecodeError):
        return False


def main(argv: list[str]) -> int:
    root = Path(argv[1] if len(argv) > 1 else Path(__file__).resolve().parents[1])
    hits = findings(root)
    if hits:
        print("probable private key material:")
        for hit in hits:
            print(f"  {hit}")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
