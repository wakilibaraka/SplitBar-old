#!/bin/bash
# Launch the built app and check it survives, renders and shuts down cleanly.
#
#   scripts/smoke_test.sh [--seconds 8] [--shot /tmp/splitbar.png]
#
# Builds a debug bundle, runs it with SPLITBAR_SKIP_DOCK=1 so the real Dock is
# never touched, then asserts three things a build and the unit tests cannot:
# the process stays alive, it logs no error or fault, and SIGTERM ends it without
# a crash. A screenshot is taken so the UI can be eyeballed.
set -uo pipefail

cd "$(dirname "$0")/.."

SECONDS_TO_RUN="${SECONDS_TO_RUN:-8}"
SHOT="${SHOT:-}"
while [ $# -gt 0 ]; do
  case "$1" in
    --seconds) SECONDS_TO_RUN="$2"; shift 2 ;;
    --shot) SHOT="$2"; shift 2 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done

if [ -z "${DEVELOPER_DIR:-}" ] && [ -d /Applications/Xcode.app/Contents/Developer ]; then
  export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
fi

VERSION="0.3.0-smoke"
LOG_FILE="$(mktemp -t splitbar-smoke)"
RUN_LOG="$(mktemp -t splitbar-smoke-run)"
START="$(date +%s)"
status=0

cleanup() {
  if pgrep -f "SplitBar.app/Contents/MacOS/SplitBar" > /dev/null 2>&1; then
    pkill -f "SplitBar.app/Contents/MacOS/SplitBar" 2> /dev/null
  fi
}
trap cleanup EXIT

echo "==> Building"
if ! ./scripts/build_app.sh "$VERSION" > "$LOG_FILE" 2>&1; then
  echo "FAIL: build failed"; tail -20 "$LOG_FILE"; exit 1
fi

echo "==> Launching (SPLITBAR_SKIP_DOCK=1, the real Dock is left alone)"
SPLITBAR_SKIP_DOCK=1 ./SplitBar.app/Contents/MacOS/SplitBar > "$RUN_LOG" 2>&1 &
APP_PID=$!

sleep "$SECONDS_TO_RUN"

echo "==> Checking the process survived"
if ! kill -0 "$APP_PID" 2> /dev/null; then
  echo "FAIL: the app exited during startup"
  tail -20 "$RUN_LOG"
  exit 1
fi

echo "==> Checking for errors and faults in the log"
/usr/bin/log show --predicate 'subsystem == "com.baraka.splitbar" AND (messageType == error OR messageType == fault)' \
  --start "$(date -r "$START" '+%Y-%m-%d %H:%M:%S')" --style compact 2> /dev/null \
  | grep -E "^[0-9]{4}-[0-9]{2}-[0-9]{2} " \
  | grep -v "swiftpm-testing-helper" > "$LOG_FILE.faults" || true
# `log show` prints a header even when nothing matches, so only real rows count.
if [ -s "$LOG_FILE.faults" ]; then
  echo "FAIL: the app logged errors or faults:"
  cat "$LOG_FILE.faults"
  status=1
else
  echo "    none"
fi

if [ -n "$SHOT" ]; then
  echo "==> Screenshot to $SHOT"
  screencapture -x "$SHOT" || echo "    (screenshot failed; is a screen recording permission granted?)"
fi

echo "==> Checking stdout for a crash report"
if grep -qE "Fatal error|Crash|Thread 0 .* crashed" "$RUN_LOG"; then
  echo "FAIL: the app reported a crash:"
  tail -20 "$RUN_LOG"
  status=1
else
  echo "    none"
fi

echo "==> Terminating with SIGTERM (this is the path that restores the Dock)"
kill -TERM "$APP_PID" 2> /dev/null
for _ in $(seq 1 20); do
  kill -0 "$APP_PID" 2> /dev/null || break
  sleep 0.5
done

if kill -0 "$APP_PID" 2> /dev/null; then
  echo "FAIL: the app did not exit within 10s of SIGTERM"
  status=1
else
  echo "    exited cleanly"
fi

if [ "$status" -eq 0 ]; then
  echo "PASS: the app launches, runs without faults and shuts down cleanly"
else
  echo "FAIL: see above"
fi
rm -f "$LOG_FILE" "$LOG_FILE.faults" "$RUN_LOG"
exit "$status"
