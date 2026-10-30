import os
import subprocess
import sys

adb = os.path.expandvars(r"%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe")
if not os.path.exists(adb):
    adb = "adb"

print("Starting logcat watcher...")
sys.stdout.flush()

proc = subprocess.Popen(
    [adb, "logcat", "-v", "time"],
    stdout=subprocess.PIPE,
    stderr=subprocess.STDOUT,
    text=True,
    encoding="utf-8",
    errors="replace",
)

keywords = [
    "com.mechupp",
    "flutter",
    "firebase",
    "fatal",
    "exception",
    "dio",
    "renderflex",
    "overflowed",
    "error",
]

try:
    for line in iter(proc.stdout.readline, ""):
        line_lower = line.lower()
        if any(k in line_lower for k in keywords):
            # Exclude noisy non-relevant logs
            if "egl" in line_lower or "gles" in line_lower or "chatty" in line_lower:
                continue
            print(line, end="")
            sys.stdout.flush()
except KeyboardInterrupt:
    proc.terminate()
