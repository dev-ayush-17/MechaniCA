# Regenerates backend/openapi.json and the Dart client (ADR-012). Run from the repo root.
$ErrorActionPreference = 'Stop'

Push-Location backend
try {
    $python = if (Test-Path .venv/Scripts/python.exe) { '.venv/Scripts/python.exe' } else { 'python' }
    & $python scripts/export_openapi.py
} finally { Pop-Location }

Push-Location app
try {
    dart run swagger_parser
    dart run build_runner build --delete-conflicting-outputs
} finally { Pop-Location }
