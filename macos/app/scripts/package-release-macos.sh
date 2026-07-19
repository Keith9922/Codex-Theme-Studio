#!/bin/bash

set -euo pipefail

APP_ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"
MACOS_ROOT="$(cd "$APP_ROOT/.." && pwd -P)"
REPO_ROOT="$(cd "$MACOS_ROOT/.." && pwd -P)"
VERSION="$(/usr/bin/tr -d '[:space:]' < "$MACOS_ROOT/VERSION")"
RELEASE_ROOT="${1:-$MACOS_ROOT/release}"
APP_ARCHIVE="$RELEASE_ROOT/Codex-Dream-Skin-macOS-v$VERSION.zip"
SKILL_ARCHIVE="$RELEASE_ROOT/create-codex-dream-skin-skill-v$VERSION.zip"
CHECKSUMS="$RELEASE_ROOT/SHA256SUMS-v$VERSION.txt"

"$APP_ROOT/scripts/build-app-macos.sh" "$RELEASE_ROOT"

/bin/rm -f "$APP_ARCHIVE" "$SKILL_ARCHIVE" "$CHECKSUMS"
COPYFILE_DISABLE=1 /usr/bin/ditto -c -k --sequesterRsrc --keepParent \
  "$RELEASE_ROOT/Codex Dream Skin.app" "$APP_ARCHIVE"
COPYFILE_DISABLE=1 /usr/bin/ditto -c -k --keepParent --norsrc --noextattr \
  "$REPO_ROOT/skills/create-codex-dream-skin" "$SKILL_ARCHIVE"

for archive in "$APP_ARCHIVE" "$SKILL_ARCHIVE"; do
  hash="$(/usr/bin/shasum -a 256 "$archive" | /usr/bin/awk '{print $1}')"
  /usr/bin/printf '%s  %s\n' "$hash" "$(/usr/bin/basename "$archive")" >> "$CHECKSUMS"
done

/usr/bin/printf '%s\n%s\n%s\n' "$APP_ARCHIVE" "$SKILL_ARCHIVE" "$CHECKSUMS"
