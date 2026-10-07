#!/bin/bash
set -e
cd "$(dirname "$0")"
swift build -c debug
rm -rf SplitBar.app
mkdir -p SplitBar.app/Contents/MacOS SplitBar.app/Contents/Helpers
cp .build/debug/SplitBar SplitBar.app/Contents/MacOS/SplitBar
cp .build/debug/SplitBarDockRestore SplitBar.app/Contents/Helpers/SplitBarDockRestore
cp Info.plist SplitBar.app/Contents/Info.plist
codesign --force --sign - SplitBar.app 2>/dev/null || true
killall SplitBar 2>/dev/null || true
open SplitBar.app
