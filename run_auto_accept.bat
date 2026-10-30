@echo off
title MechUpp Auto-Accept Daemon
echo ========================================================
echo Starting MechUpp Auto-Accept Dispatcher for Staging...
echo Keep this window OPEN while team members test bookings.
echo ========================================================
cd /d "%~dp0backend"
.venv\Scripts\python scripts/watch_and_auto_accept.py
pause
