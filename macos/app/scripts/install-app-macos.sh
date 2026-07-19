#!/bin/bash

set -euo pipefail

APP_ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"
MACOS_ROOT="$(cd "$APP_ROOT/.." && pwd -P)"
SOURCE_APP="${1:-$MACOS_ROOT/release/Codex Dream Skin.app}"
INSTALL_ROOT="$HOME/Applications"
DESTINATION="$INSTALL_ROOT/Codex Dream Skin.app"
TEMP_DESTINATION="$INSTALL_ROOT/.Codex Dream Skin.app.installing.$$"

[ -d "$SOURCE_APP" ] || {
  printf 'Application bundle was not found: %s\n' "$SOURCE_APP" >&2
  exit 1
}

/usr/bin/osascript -e 'tell application id "com.local.codex-dream-skin-manager" to quit' \
  >/dev/null 2>&1 || true
/bin/sleep 0.5

/bin/mkdir -p "$INSTALL_ROOT"
/bin/rm -rf "$TEMP_DESTINATION"
/usr/bin/ditto "$SOURCE_APP" "$TEMP_DESTINATION"
/usr/bin/codesign --verify --deep --strict "$TEMP_DESTINATION"
/bin/rm -rf "$DESTINATION"
/bin/mv "$TEMP_DESTINATION" "$DESTINATION"

/usr/bin/open "$DESTINATION"
printf '%s\n' "$DESTINATION"
