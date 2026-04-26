#!/usr/bin/env bash
# obsidian-cli.sh — wrapper for the Obsidian CLI used by every claude-obsidian skill.
#
# Resolves the vault, derives the vault name, runs the verb, and normalizes
# exit codes per _shared/cli.md.
#
# Usage:
#   scripts/obsidian-cli.sh <verb> [arg=value ...]
#
# Exit codes (see _shared/cli.md for the full table):
#   0 — success
#   1 — generic CLI error (stdout starts with "Error:")
#   2 — vault not found (stdout literal first line "Vault not found.")
#   3 — pre-flight failed (obsidian binary missing, not running, or version probe failed)
#   4 — vault resolution failed (resolve-vault.sh exited non-zero)
#
# stdout/stderr from the underlying CLI are passed through verbatim.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 1. Resolve vault path. Failure is exit 4 — callers that want fail-soft chain `|| exit 0`.
VAULT="$("$SCRIPT_DIR/resolve-vault.sh")" || exit 4
[ -n "$VAULT" ] || exit 4

# 2. Derive vault name (basename) — CLI accepts vault=<name>, not path.
VAULT_NAME="$(basename "$VAULT")"

# 3. Pre-flight: obsidian binary present and Obsidian running.
#    `obsidian version` returns "X.Y.Z (installer A.B.C)" when the desktop app
#    is reachable. Empty output or non-zero exit → bail with exit 3.
if ! command -v obsidian >/dev/null 2>&1; then
  echo "obsidian-cli: obsidian binary not on PATH" >&2
  exit 3
fi
VERSION_OUT="$(obsidian version 2>/dev/null || true)"
if [ -z "$VERSION_OUT" ]; then
  echo "obsidian-cli: 'obsidian version' returned no output (Obsidian not running?)" >&2
  exit 3
fi

# 4. Run the verb. Capture stdout so we can inspect it for error markers.
#    The CLI itself always exits 0, so its real exit is uninformative — we
#    detect errors from stdout per _shared/cli.md.
TMP_OUT="$(mktemp)"
trap 'rm -f "$TMP_OUT"' EXIT

obsidian "vault=$VAULT_NAME" "$@" >"$TMP_OUT" 2>&2
CLI_EXIT=$?

# 5. Pass stdout through to the caller verbatim.
cat "$TMP_OUT"

# 6. Normalize exit code based on stdout's first line.
FIRST_LINE="$(head -n 1 "$TMP_OUT" 2>/dev/null || true)"

# Honour the CLI's own non-zero exit if it ever emits one.
if [ "$CLI_EXIT" -ne 0 ]; then
  exit "$CLI_EXIT"
fi

case "$FIRST_LINE" in
  "Vault not found."*) exit 2 ;;
  "Error: "*)          exit 1 ;;
  *)                   exit 0 ;;
esac
