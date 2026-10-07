#!/bin/bash
# Debug wrapper: assembles and opens a debug SplitBar.app.
set -e
cd "$(dirname "$0")"
VERSION="$(./scripts/build_app.sh 0.0.0-dev 2>&1 | tail -1 | sed -E 's/.*version ([0-9.]+-dev).*/\1/' || echo 0.0.0-dev)"
killall SplitBar 2>/dev/null || true
open SplitBar.app
