"""One Admin SDK app per process. Adapters must not each call initialize_app."""

from __future__ import annotations

from pathlib import Path

import firebase_admin
from firebase_admin import credentials


def ensure_firebase(
    project_id: str,
    *,
    credentials_path: str | None = None,
    database_url: str | None = None,
) -> firebase_admin.App:
    try:
        return firebase_admin.get_app()
    except ValueError:
        pass
    options: dict[str, str] = {}
    if project_id:
        options["projectId"] = project_id
    if database_url:
        options["databaseURL"] = database_url
    cred = None
    if credentials_path:
        path = Path(credentials_path)
        if not path.is_file():
            raise FileNotFoundError(f"Firebase credentials not found: {path}")
        cred = credentials.Certificate(str(path))
    if cred is not None:
        return firebase_admin.initialize_app(cred, options or None)
    return firebase_admin.initialize_app(options=options or None)
