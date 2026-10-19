#!/bin/sh
# Regenerates backend/openapi.json and the Dart client (ADR-012). Run from the repo root.
set -eu

(cd backend && python scripts/export_openapi.py)
(cd app && dart run swagger_parser && dart run build_runner build --delete-conflicting-outputs)
