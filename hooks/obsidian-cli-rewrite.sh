#!/usr/bin/env bash
# obsidian-cli-rewrite.sh — PreToolUse hook (matcher: Bash).
#
# Transparently rewrites raw `obsidian ...` invocations into calls through
# scripts/obsidian-cli.sh so that vault resolution, the version pre-flight,
# and exit-code normalization always apply. Inspired by RTK's hook pattern
# (https://github.com/rtk-ai/rtk).
#
# Rewrite is deliberately conservative:
#   - Only rewrites commands whose FIRST token is exactly `obsidian` (so
#     `which obsidian`, `pgrep obsidian`, `cat $obsidian_path` are untouched).
#   - Skips if the command already mentions `obsidian-cli` anywhere.
#   - On any error (jq missing, malformed JSON), exits 0 → unchanged.
#
# Output protocol: emits `hookSpecificOutput` with `permissionDecision: allow`
# and `updatedInput.command` set to the rewritten form. The model never sees
# the rewrite — the new command runs as if it had been authored that way.

set -u

# Need jq to parse and emit hook JSON. Without it, pass through unchanged.
if ! command -v jq >/dev/null 2>&1; then
  exit 0
fi

INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
[ -z "$CMD" ] && exit 0

# Already routed through the wrapper — nothing to do.
case "$CMD" in
  *obsidian-cli*) exit 0 ;;
esac

# First token (after leading whitespace) must be exactly `obsidian`.
# `read -r FIRST REST` splits on the first whitespace.
read -r FIRST REST <<<"$CMD"
[ "$FIRST" = "obsidian" ] || exit 0

# Build the rewritten command. Leave ${CLAUDE_PLUGIN_ROOT} unexpanded so the
# rewrite is portable across users — Bash will expand it at execution time.
REWRITTEN="\"\${CLAUDE_PLUGIN_ROOT}/scripts/obsidian-cli.sh\" $REST"

# Emit the rewritten tool_input. Preserve all other fields (e.g. `description`).
ORIGINAL_INPUT=$(echo "$INPUT" | jq -c '.tool_input')
UPDATED_INPUT=$(echo "$ORIGINAL_INPUT" | jq --arg cmd "$REWRITTEN" '.command = $cmd')

jq -n \
  --argjson updated "$UPDATED_INPUT" \
  '{
    "hookSpecificOutput": {
      "hookEventName": "PreToolUse",
      "permissionDecision": "allow",
      "permissionDecisionReason": "obsidian-cli auto-rewrite (claude-obsidian)",
      "updatedInput": $updated
    }
  }'
