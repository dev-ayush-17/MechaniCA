"""Fail if a vendor SDK is imported outside an adapter directory.

Rule (AGENTS.md): Firebase, Cashfree, and Google Maps SDKs live only in adapters.
Dart adapters: any path containing `/data/adapters/`.
Python adapters: `backend/app/adapters/`.

Usage: python tool/check_import_boundaries.py [repo_root]
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

DART_BANNED = (
    "cloud_firestore",
    "firebase_core",
    "firebase_auth",
    "firebase_database",
    "firebase_storage",
    "firebase_messaging",
    "flutter_cashfree_pg_sdk",
    "cashfree",
    "google_maps_flutter",
    "google_maps",
)
PY_BANNED = ("firebase_admin", "google.cloud", "cashfree", "googlemaps")

DART_IMPORT = re.compile(r"""^\s*(?:import|export)\s+['"]package:([^/'"]+)""")
PY_IMPORT = re.compile(r"^\s*(?:from|import)\s+([\w.]+)")


def _dart_violations(path: Path) -> list[str]:
    if "/data/adapters/" in path.as_posix():
        return []
    found = []
    for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
        match = DART_IMPORT.match(line)
        if match and match.group(1) in DART_BANNED:
            found.append(f"{path}:{number}: {match.group(1)} outside data/adapters")
    return found


def _py_violations(path: Path) -> list[str]:
    if "/app/adapters/" in path.as_posix():
        return []
    found = []
    for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
        match = PY_IMPORT.match(line)
        if match and any(
            match.group(1) == banned or match.group(1).startswith(banned + ".")
            for banned in PY_BANNED
        ):
            found.append(f"{path}:{number}: {match.group(1)} outside app/adapters")
    return found


def scan(root: Path) -> list[str]:
    violations: list[str] = []
    for base in ("app/lib", "app/test"):
        for path in sorted((root / base).rglob("*.dart")):
            violations += _dart_violations(path)
    for path in sorted((root / "backend/app").rglob("*.py")):
        violations += _py_violations(path)
    return violations


def main() -> int:
    root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path.cwd()
    violations = scan(root)
    for violation in violations:
        print(violation)
    if violations:
        print(f"{len(violations)} import boundary violation(s).")
        return 1
    print("Import boundaries OK.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
