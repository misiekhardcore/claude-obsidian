#!/usr/bin/env bash
# Write ~/.config/obsidian/obsidian.json with the given vault registered.
#
# Schema (empirical — see #89 Section H, "obsidian.json schema"):
#   {
#     "cli": true,
#     "vaults": {"<id>": {"path": "<abs path>", "ts": <ms>, "open": true}}
#   }
#
# `cli: true` enables the IPC channel that `obsidian-cli` talks to. Without
# it, every CLI verb returns "Command line interface is not enabled."
# Verified against the Obsidian 1.12.7 source (`obsidian.asar` -> main.js;
# the runtime toggle is `ipcMain.on("cli", ...)` and persists as `C.cli`).
# Future minor versions may break the direct-write path silently — the
# wait-for-obsidian.sh probe (which calls `obsidian read`) catches that as
# a timeout.
#
# Idempotent: re-running with the same VAULT_PATH replaces the existing entry
# (id is derived from a SHA-1 of the path, so collisions are vanishingly
# improbable and the same path always maps to the same id).
#
# Usage:
#   register-vault.sh /absolute/path/to/vault

set -euo pipefail

VAULT_PATH="${1:-}"
if [ -z "$VAULT_PATH" ]; then
  echo "Usage: register-vault.sh /absolute/path/to/vault" >&2
  exit 2
fi

if [ ! -d "$VAULT_PATH" ]; then
  echo "register-vault: vault path does not exist: $VAULT_PATH" >&2
  exit 1
fi

CONFIG_DIR="$HOME/.config/obsidian"
CONFIG_FILE="$CONFIG_DIR/obsidian.json"
mkdir -p "$CONFIG_DIR"

ID=$(printf '%s' "$VAULT_PATH" | sha1sum | cut -c1-16)
TS=$(date +%s%3N)

if [ -f "$CONFIG_FILE" ]; then
  tmp=$(mktemp)
  jq --arg id "$ID" --arg path "$VAULT_PATH" --argjson ts "$TS" \
     '.cli = true | .vaults[$id] = {path: $path, ts: $ts, open: true}' \
     "$CONFIG_FILE" > "$tmp"
  mv "$tmp" "$CONFIG_FILE"
else
  jq -n --arg id "$ID" --arg path "$VAULT_PATH" --argjson ts "$TS" \
     '{cli: true, vaults: {($id): {path: $path, ts: $ts, open: true}}}' \
     > "$CONFIG_FILE"
fi

echo "register-vault: registered $VAULT_PATH (id=$ID)"
