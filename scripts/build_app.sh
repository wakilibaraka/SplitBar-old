#!/bin/bash
# Build SplitBar.app.
#
#   scripts/build_app.sh <version> [--release] [--sign "Developer ID Application: ..."]
#
# Produces a bundle with:
#   Contents/MacOS/SplitBar              main agent (LSUIElement)
#   Contents/Helpers/SplitBarDockRestore login-time Dock restore helper
#   Contents/Resources/AppIcon.icns      placeholder icon
#   Contents/Info.plist                  version taken from <version>
#   Contents/LoginItems/com.baraka.splitbar.restore.plist  login agent definition
#
# Release builds additionally strip debug info, map build paths out of the
# binary, delete the Xcode toolchain rpath, and sign the helper with a stable
# identifier so it is recognisable to Gatekeeper and Login Items.
set -euo pipefail

cd "$(dirname "$0")/.."
ROOT="$(pwd)"

# Pin the toolchain so a bare CLT default can never produce a different binary.
if [ -z "${DEVELOPER_DIR:-}" ] && [ -d /Applications/Xcode.app/Contents/Developer ]; then
  export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
fi

VERSION="${1:-}"
CONFIGURATION="debug"
SIGN_IDENTITY="-"

while [ $# -gt 0 ]; do
  case "$1" in
    --release) CONFIGURATION="release" ;;
    --sign) shift; SIGN_IDENTITY="${1:--}" ;;
    *) ;;
  esac
  shift || true
done

if [ -z "$VERSION" ]; then
  echo "usage: scripts/build_app.sh <version> [--release] [--sign <identity>]" >&2
  exit 2
fi

if ! [[ "$VERSION" =~ ^[0-9]+(\.[0-9]+){0,2}([a-zA-Z0-9.-]*)$ ]]; then
  echo "error: version '$VERSION' is not a dotted version number" >&2
  exit 2
fi

BUILD_NUMBER="$(git rev-list --count HEAD 2>/dev/null || echo 0)"
APP="SplitBar.app"
APP_DIR="$APP/Contents"

SWIFT_FLAGS=(-Xswiftc -warnings-as-errors)
if [ "$CONFIGURATION" = "release" ]; then
  # Never let local absolute paths reach the shipped binary.
  SWIFT_FLAGS+=(
    -Xswiftc -file-prefix-map -Xswiftc "$ROOT=."
    -Xswiftc -debug-prefix-map -Xswiftc "$ROOT=."
  )
fi

echo "==> Building ($CONFIGURATION) with prefix mapping"
/usr/bin/arch -arm64 xcrun swift build -c "$CONFIGURATION" "${SWIFT_FLAGS[@]}"
/usr/bin/arch -arm64 xcrun swift build -c "$CONFIGURATION" --product SplitBarDockRestore "${SWIFT_FLAGS[@]}"

APP_BINARY="$ROOT/.build/$CONFIGURATION/SplitBar"
HELPER_BINARY="$ROOT/.build/$CONFIGURATION/SplitBarDockRestore"
# SwiftPM may place products under an architecture-scoped triple directory.
if [ ! -x "$APP_BINARY" ]; then
  APP_BINARY="$(ls -1 "$ROOT"/.build/*/"$CONFIGURATION"/SplitBar 2>/dev/null | head -1 || true)"
fi
if [ ! -x "$HELPER_BINARY" ]; then
  HELPER_BINARY="$(ls -1 "$ROOT"/.build/*/"$CONFIGURATION"/SplitBarDockRestore 2>/dev/null | head -1 || true)"
fi

fail() { echo "error: $1" >&2; exit 1; }
[ -x "$APP_BINARY" ] || fail "main binary not found (expected .build/$CONFIGURATION/SplitBar)"
[ -x "$HELPER_BINARY" ] || fail "restore helper not found (expected .build/$CONFIGURATION/SplitBarDockRestore)"

echo "==> Assembling $APP"
rm -rf "$APP"
mkdir -p "$APP_DIR/MacOS" "$APP_DIR/Helpers" "$APP_DIR/Resources" "$APP_DIR/LoginItems"
cp "$APP_BINARY" "$APP_DIR/MacOS/SplitBar"
cp "$HELPER_BINARY" "$APP_DIR/Helpers/SplitBarDockRestore"

[ -f "$ROOT/Resources/AppIcon.icns" ] || fail "Resources/AppIcon.icns is missing. Create it before packaging."
cp "$ROOT/Resources/AppIcon.icns" "$APP_DIR/Resources/AppIcon.icns"

echo "==> Writing Info.plist (version $VERSION, build $BUILD_NUMBER)"
cp "$ROOT/Info.plist" "$APP_DIR/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$APP_DIR/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER" "$APP_DIR/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleIconFile AppIcon" "$APP_DIR/Info.plist" 2>/dev/null || \
  /usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string AppIcon" "$APP_DIR/Info.plist"
for key in CFBundleIdentifier CFBundleExecutable CFBundleName; do
  /usr/libexec/PlistBuddy -c "Print :$key" "$APP_DIR/Info.plist" >/dev/null || \
    fail "Info.plist is missing $key"
done

echo "==> Embedding login agent definition"
cat > "$APP_DIR/LoginItems/com.baraka.splitbar.restore.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key><string>com.baraka.splitbar.restore</string>
    <key>ProgramArguments</key>
    <array><string>$ROOT/$APP_DIR/Helpers/SplitBarDockRestore</string></array>
    <key>RunAtLoad</key><true/>
</dict>
</plist>
PLIST

if [ "$CONFIGURATION" = "release" ]; then
  echo "==> Stripping debug info and deleting toolchain rpaths"
  strip -x "$APP_DIR/MacOS/SplitBar" 2>/dev/null || true
  strip -x "$APP_DIR/Helpers/SplitBarDockRestore" 2>/dev/null || true
  while read -r rpath; do
    install_name_tool -delete_rpath "$rpath" "$APP_DIR/MacOS/SplitBar" 2>/dev/null || true
  done < <(otool -l "$APP_DIR/MacOS/SplitBar" | awk '/path /{print $2}' | grep -E 'Xcode|\.build' || true)
fi

echo "==> Signing (identity: $SIGN_IDENTITY)"
# Inner binary first, then the bundle. The helper gets a stable identifier so
# Gatekeeper and Login Items can name it.
codesign --force --sign "$SIGN_IDENTITY" --options runtime \
  --identifier com.baraka.splitbar.dockrestore \
  "$APP_DIR/Helpers/SplitBarDockRestore" 2>/dev/null || \
  codesign --force --sign "$SIGN_IDENTITY" --identifier com.baraka.splitbar.dockrestore \
    "$APP_DIR/Helpers/SplitBarDockRestore" 2>/dev/null || true
codesign --force --sign "$SIGN_IDENTITY" --options runtime "$APP" 2>/dev/null || \
  codesign --force --sign "$SIGN_IDENTITY" "$APP" 2>/dev/null || \
  codesign --force --deep --sign - "$APP"

echo "==> Verifying"
codesign --verify --deep --strict "$APP"
[ -x "$APP_DIR/Helpers/SplitBarDockRestore" ] || fail "helper missing from bundle"

if [ "$CONFIGURATION" = "release" ]; then
  leaks="$(strings -a "$APP_DIR/MacOS/SplitBar" | grep -c "$ROOT" || true)"
  if [ "$leaks" -gt 0 ]; then
    echo "warning: binary still contains $leaks build-path strings" >&2
  fi
  if otool -l "$APP_DIR/MacOS/SplitBar" | grep -q "Xcode.app"; then
    echo "warning: binary still references an Xcode rpath" >&2
  fi
fi

if [ "$CONFIGURATION" != "release" ]; then
  echo
  echo "NOTE: this is a debug bundle."
  echo "      It keeps debug symbols and local build paths, so it must not be"
  echo "      distributed. Use --release for anything you ship."
fi

echo "==> Built $APP ($VERSION, build $BUILD_NUMBER)"
du -sh "$APP" | sed 's/^/    /'
