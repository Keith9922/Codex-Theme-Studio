#!/bin/bash

set -euo pipefail

APP_ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"
MACOS_ROOT="$(cd "$APP_ROOT/.." && pwd -P)"
OUTPUT_ROOT="${1:-$MACOS_ROOT/release}"
APP_NAME="Codex Dream Skin.app"
APP_BUNDLE="$OUTPUT_ROOT/$APP_NAME"
TEMP_BUNDLE="$OUTPUT_ROOT/.Codex Dream Skin.app.building.$$"
TEMP_ICONSET="$OUTPUT_ROOT/.DreamSkin.$$.iconset"

cleanup() {
  /bin/rm -rf "$TEMP_BUNDLE" "$TEMP_ICONSET"
}
trap cleanup EXIT

/bin/mkdir -p "$OUTPUT_ROOT"
cd "$APP_ROOT"
/usr/bin/swift build -c release

BINARY="$APP_ROOT/.build/release/CodexDreamSkin"
[ -x "$BINARY" ] || { printf 'Built application binary is missing: %s\n' "$BINARY" >&2; exit 1; }

/bin/mkdir -p \
  "$TEMP_BUNDLE/Contents/MacOS" \
  "$TEMP_BUNDLE/Contents/Resources/engine"
/bin/cp "$BINARY" "$TEMP_BUNDLE/Contents/MacOS/CodexDreamSkin"
/bin/cp "$APP_ROOT/Info.plist" "$TEMP_BUNDLE/Contents/Info.plist"
/usr/bin/swift "$APP_ROOT/scripts/generate-app-icon.swift" "$TEMP_ICONSET"
/usr/bin/iconutil -c icns "$TEMP_ICONSET" -o "$TEMP_BUNDLE/Contents/Resources/DreamSkin.icns"
/usr/bin/rsync -a \
  --exclude '.DS_Store' \
  --exclude 'app/' \
  --exclude 'release/' \
  --exclude 'runtime/' \
  --exclude 'tests/' \
  --exclude 'presets/preset-asuka-eva02/' \
  --exclude 'presets/preset-beagle-duodong/' \
  "$MACOS_ROOT/" "$TEMP_BUNDLE/Contents/Resources/engine/"

/bin/chmod 755 "$TEMP_BUNDLE/Contents/MacOS/CodexDreamSkin"
/bin/chmod 700 "$TEMP_BUNDLE/Contents/Resources/engine/scripts/"*.sh
/usr/bin/codesign --force --deep --sign - "$TEMP_BUNDLE"
/usr/bin/codesign --verify --deep --strict "$TEMP_BUNDLE"

/bin/rm -rf "$APP_BUNDLE"
/bin/mv "$TEMP_BUNDLE" "$APP_BUNDLE"
trap - EXIT
printf '%s\n' "$APP_BUNDLE"
