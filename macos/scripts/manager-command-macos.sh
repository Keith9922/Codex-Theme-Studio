#!/bin/bash

# Serialized command surface for the native menu bar app. This is the only
# runtime entry point the app uses for operations that can restart Codex.

set -Eeuo pipefail
. "$(cd "$(dirname "$0")" && pwd -P)/common-macos.sh"

COMMAND="${1:-}"
[ -n "$COMMAND" ] || fail "Usage: manager-command-macos.sh <enable|disable|switch|open|seed-library|migrate-legacy>"
shift

PORT=9341
THEME_ID=""
APPLY_IF_ACTIVE="false"
while [ "$#" -gt 0 ]; do
  case "$1" in
    --port) PORT="${2:-}"; shift 2 ;;
    --theme|--id) THEME_ID="${2:-}"; shift 2 ;;
    --apply-if-active) APPLY_IF_ACTIVE="true"; shift ;;
    *) fail "Unknown manager argument: $1" ;;
  esac
done

case "$PORT" in ''|*[!0-9]*) fail "Invalid port: $PORT" ;; esac
[ "$PORT" -ge 1024 ] && [ "$PORT" -le 65535 ] || fail "Port must be between 1024 and 65535."
if [ -n "$THEME_ID" ]; then
  case "$THEME_ID" in
    *[!A-Za-z0-9_-]*|'') fail "Theme id may contain only letters, numbers, underscores, and hyphens." ;;
  esac
  [ "${#THEME_ID}" -le 80 ] || fail "Theme id is too long."
fi

ensure_state_root
MANAGER_LOCK="$STATE_ROOT/manager-operation.lock"

lock_owner_alive() {
  local owner_file="$MANAGER_LOCK/owner"
  local owner_pid=""
  if [ ! -f "$owner_file" ]; then
    # Another process may be between atomic mkdir and writing its owner file.
    # Treat a fresh owner-less directory as busy instead of deleting its lock.
    local modified=""
    modified="$(/usr/bin/stat -f '%m' "$MANAGER_LOCK" 2>/dev/null || true)"
    case "$modified" in ''|*[!0-9]*) return 1 ;; esac
    [ $(( $(/bin/date '+%s') - modified )) -lt 5 ]
    return
  fi
  owner_pid="$(/usr/bin/sed -n '1p' "$owner_file" 2>/dev/null || true)"
  case "$owner_pid" in ''|*[!0-9]*) return 1 ;; esac
  /bin/kill -0 "$owner_pid" 2>/dev/null
}

acquire_manager_lock() {
  local deadline=$((SECONDS + 12))
  while ! /bin/mkdir "$MANAGER_LOCK" 2>/dev/null; do
    if [ -L "$MANAGER_LOCK" ] || [ ! -d "$MANAGER_LOCK" ]; then
      fail "Unsafe Dream Skin manager lock path: $MANAGER_LOCK"
    fi
    if ! lock_owner_alive; then
      /bin/rm -rf "$MANAGER_LOCK" 2>/dev/null || true
      continue
    fi
    [ "$SECONDS" -lt "$deadline" ] \
      || fail "Another Dream Skin operation is still running. Try again after it finishes."
    /bin/sleep 0.15
  done
  /bin/chmod 700 "$MANAGER_LOCK"
  /usr/bin/printf '%s\n%s\n' "$$" "$(/bin/date -u '+%Y-%m-%dT%H:%M:%SZ')" > "$MANAGER_LOCK/owner"
  /bin/chmod 600 "$MANAGER_LOCK/owner"
}

release_manager_lock() {
  local recorded=""
  [ -f "$MANAGER_LOCK/owner" ] && recorded="$(/usr/bin/sed -n '1p' "$MANAGER_LOCK/owner" 2>/dev/null || true)"
  [ "$recorded" = "$$" ] && /bin/rm -rf "$MANAGER_LOCK" 2>/dev/null || true
}

acquire_manager_lock
trap release_manager_lock EXIT

prepare_theme_runtime() {
  discover_codex_app
  require_macos_runtime
  ensure_state_root
  seed_bundled_presets

  if [ -n "$THEME_ID" ]; then
    "$SCRIPT_DIR/switch-theme-macos.sh" --id "$THEME_ID" --no-apply >/dev/null
  elif [ ! -f "$THEME_DIR/theme.json" ]; then
    "$SCRIPT_DIR/switch-theme-macos.sh" --id preset-midnight-aurora --no-apply >/dev/null
  fi

  [ -f "$CONFIG_PATH" ] \
    || fail "Codex config was not found. Open Codex once, close it, then enable Dream Skin again."
  if [ ! -f "$THEME_BACKUP_PATH" ]; then
    # Enabling is an explicit restart-authorized action from the app. Config is
    # only read while Codex is fully stopped, preserving the existing guardrail.
    codex_is_running && stop_codex true
    "$NODE" "$SCRIPT_DIR/theme-config.mjs" install "$CONFIG_PATH" "$THEME_BACKUP_PATH" >/dev/null
  fi
  "$NODE" "$INJECTOR" --check-payload --theme-dir "$THEME_DIR" >/dev/null
}

migrate_legacy_entry_points() {
  local uid
  local legacy_root="$STATE_ROOT/legacy-entry-points"
  local stamp
  uid="$(/usr/bin/id -u)"
  stamp="$(/bin/date '+%Y%m%d-%H%M%S')"
  /bin/mkdir -p "$legacy_root"
  /bin/chmod 700 "$legacy_root"

  # Remove the one-shot completion job created by the earlier scripted setup.
  /bin/launchctl bootout "gui/$uid/com.local.codex-dream-skin-asuka-complete" >/dev/null 2>&1 || true
  /bin/launchctl remove "com.local.codex-dream-skin-asuka-complete" >/dev/null 2>&1 || true
  legacy_plist="$HOME/Library/LaunchAgents/com.local.codex-dream-skin-asuka-complete.plist"
  if [ -f "$legacy_plist" ]; then
    /bin/mv "$legacy_plist" "$legacy_root/com.local.codex-dream-skin-asuka-complete.$stamp.plist"
  fi

  # SwiftBar polls and invokes the old command surface independently. Archive
  # only the exact Dream Skin plugin filename; leave unrelated plugins intact.
  for swiftbar_root in \
    "$HOME/Library/Application Support/SwiftBar/Plugins" \
    "$HOME/Library/Application Support/SwiftBar/plugins"; do
    legacy_swiftbar="$swiftbar_root/codex_dream_skin.10s.sh"
    if [ -f "$legacy_swiftbar" ]; then
      /bin/mv "$legacy_swiftbar" "$legacy_root/codex_dream_skin.10s.$stamp.sh"
    fi
  done

  # Desktop launchers remain useful as recovery tools, but they should not be
  # the normal control surface once the native manager is installed.
  printf 'Legacy automatic Dream Skin entry points were migrated.\n'
}

case "$COMMAND" in
  enable)
    prepare_theme_runtime
    "$SCRIPT_DIR/start-dream-skin-macos.sh" --port "$PORT" --restart-existing
    ;;
  disable)
    discover_codex_app
    require_macos_runtime
    was_running="false"
    codex_is_running && was_running="true"
    if [ -f "$THEME_BACKUP_PATH" ]; then
      restore_args=(--port "$PORT" --restore-base-theme)
      [ "$was_running" = "true" ] && restore_args+=(--restart-codex)
      "$SCRIPT_DIR/restore-dream-skin-macos.sh" "${restore_args[@]}"
    else
      "$SCRIPT_DIR/pause-dream-skin-macos.sh" --port "$PORT"
      if [ "$was_running" = "true" ]; then
        stop_codex true
        launch_codex_normally
      fi
      /bin/rm -f "$STATE_PATH"
    fi
    ;;
  switch)
    [ -n "$THEME_ID" ] || fail "Switch requires --id <theme-id>."
    if [ "$APPLY_IF_ACTIVE" = "true" ]; then
      session="$("$SCRIPT_DIR/status-dream-skin-macos.sh" --json \
        | /usr/bin/sed -n 's/.*"session":"\([^"]*\)".*/\1/p')"
      if [ "$session" = "active" ]; then
        "$SCRIPT_DIR/switch-theme-macos.sh" --id "$THEME_ID"
      else
        "$SCRIPT_DIR/switch-theme-macos.sh" --id "$THEME_ID" --no-apply
      fi
    else
      "$SCRIPT_DIR/switch-theme-macos.sh" --id "$THEME_ID" --no-apply
    fi
    ;;
  open)
    prepare_theme_runtime
    "$SCRIPT_DIR/start-dream-skin-macos.sh" --port "$PORT" --restart-existing
    ;;
  seed-library)
    seed_bundled_presets
    printf 'Bundled Dream Skin themes are ready.\n'
    ;;
  migrate-legacy)
    migrate_legacy_entry_points
    ;;
  *)
    fail "Unknown manager command: $COMMAND"
    ;;
esac
