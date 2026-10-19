"""Write the FastAPI OpenAPI schema to backend/openapi.json (ADR-012).

Run from backend/: python scripts/export_openapi.py
CI runs it and fails if the committed file or the generated Dart client is stale.
"""

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from app.main import create_app  # noqa: E402

OUTPUT = Path(__file__).resolve().parent.parent / "openapi.json"


def main() -> None:
    schema = create_app().openapi()
    text = json.dumps(schema, indent=2, sort_keys=True) + "\n"
    with OUTPUT.open("w", encoding="utf-8", newline="\n") as handle:
        handle.write(text)


if __name__ == "__main__":
    main()
