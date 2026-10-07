#!/bin/bash
# Package the release bundle into a distributable DMG.
#
#   scripts/make_release_dmg.sh <version> [--out SplitBar.dmg]
#
# Relies on `scripts/build_app.sh <version> --release`, then assembles a
# companion staging directory with an /Applications symlink so the DMG is a
# drag-install target, and compresses it with `hdiutil create`.
set -euo pipefail

cd "$(dirname "$0")/.."
ROOT="$(pwd)"

VERSION="${1:-}"
if [ -z "$VERSION" ]; then
  echo "usage: $0 <version>" >&2
  exit 2
fi
OUT="SplitBar.dmg"
while [ $# -gt 0 ]; do
  case "$1" in
    --out) OUT="$2"; shift 2 ;;
    *) shift ;;
  esac
done

APP_DIR="$ROOT/SplitBar.app"
if [ ! -d "$APP_DIR" ]; then
  echo "==> No bundle found; building a release one"
  ./scripts/build_app.sh "$VERSION" --release
fi

STAGE="$(mktemp -d "$ROOT/dmg_stage.XXXXXX")"
cleanup() {
  rm -rf "$STAGE"
}
trap cleanup EXIT

echo "==> Staging $APP_DIR"
cp -R "$APP_DIR" "$STAGE/SplitBar.app"
ln -s /Applications "$STAGE/Applications"

VOL="SplitBar"
TMP_DMG="$(mktemp "$ROOT/dmg_tmp.XXXXXX.dmg")"

echo "==> Creating $TMP_DMG"
hdiutil create -volname "$VOL" -srcfolder "$STAGE" -ov -format UDZO "$TMP_DMG"
mv "$TMP_DMG" "$OUT"

echo "==> $OUT ($(du -h "$OUT" | cut -f1))"
hdiutil verify "$OUT" | tail -2
