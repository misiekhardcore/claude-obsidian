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

# Antipattern guard (issue #98): block `obsidian create … overwrite=true` calls
# whose `path=` targets `daily/*.md`. The /daily skill must use the wrapper-only
# `create-or-append` (atomic append) and `frontmatter-set` (surgical YAML)
# verbs instead. Read-modify-overwrite of a daily file at the model layer is
# the root cause of bullet loss in #98 — this guard catches the regression.
#
# Path-scoped to `daily/*.md` so legitimate full-rewrite callers
# (daily-close synthesis, obsidian-bases templates, save promotions) are
# unaffected. Detection is substring-based on the verbatim command, so it
# survives multi-line / continuation / heredoc shapes.
DAILY_VIOLATION=0
case "$CMD" in
  *"obsidian"*"create"*)
    if printf '%s' "$CMD" | grep -qE 'path=("?)daily/[^[:space:]"]*\.md' \
       && printf '%s' "$CMD" | grep -qE 'overwrite=true|overwrite=1|overwrite([[:space:]]|$)'; then
      DAILY_VIOLATION=1
    fi
    ;;
esac

if [ "$DAILY_VIOLATION" = 1 ]; then
  jq -n '{
    "hookSpecificOutput": {
      "hookEventName": "PreToolUse",
      "permissionDecision": "deny",
      "permissionDecisionReason": "obsidian create overwrite=true on daily/*.md is forbidden (issue #98). Use obsidian create-or-append for appends or obsidian frontmatter-set for updated: bumps. See _shared/cli.md §3.1, §3.2."
    }
  }'
  exit 0
fi

# Rewrite ONLY the leading `obsidian` token on the first line. Preserves
# multi-line commands (backslash continuations, here-docs, embedded newlines)
# verbatim after the first token. Mid-string occurrences of `obsidian` (e.g.
# inside content=, comments) are not touched. Leave ${CLAUDE_PLUGIN_ROOT}
# unexpanded so the rewrite is portable — Bash expands it at execution time.
REWRITTEN=$(printf '%s' "$CMD" | sed -E '1 s~^([[:space:]]*)obsidian([[:space:]]|$)~\1"${CLAUDE_PLUGIN_ROOT}/scripts/obsidian-cli.sh"\2~')

# No-op if the leading token wasn't `obsidian` (e.g. `which obsidian`,
# `cat $obsidian_path`, `pgrep -f obsidian`).
[ "$REWRITTEN" = "$CMD" ] && exit 0

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
