#!/usr/bin/env bash
# PostToolUse hook (Bash): append a log line to $VAULT/.obsidian-cli.log for
# every Bash command that routes through obsidian-cli.sh.
#
# Silent on any failure — this hook must never disrupt a turn.

set -e

VAULT=$("${CLAUDE_PLUGIN_ROOT}/scripts/resolve-vault.sh") 2>/dev/null || exit 0
[ -d "$VAULT" ] || exit 0

INPUT=$(cat)

# Log commands that went through the obsidian-cli wrapper OR raw `obsidian`
# calls (PostToolUse may see either the pre- or post-rewrite command depending
# on the Claude Code version).
CMD=""
if command -v jq >/dev/null 2>&1; then
  CMD=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null || true)
else
  CMD=$(printf '%s' "$INPUT" \
    | grep -o '"command"[[:space:]]*:[[:space:]]*"[^"]*"' \
    | head -n1 \
    | sed 's/.*"command"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
fi

case "$CMD" in
  *obsidian-cli*) ;;
  # Raw `obsidian <verb>` — matches if PostToolUse sees the pre-rewrite input.
  obsidian\ *) ;;
  *) exit 0 ;;
esac

# Extract verb.  Two shapes:
#   rewritten: "…/obsidian-cli.sh" read path=…
#   raw:       obsidian read path=…
VERB=$(printf '%s' "$CMD" \
  | sed 's|.*obsidian-cli\.sh[^[:space:]]*[[:space:]]*||; s|^obsidian[[:space:]]*||' \
  | awk '{print $1}')

# Extract key path arg (path= or file=).
KEY_ARG=$(printf '%s' "$CMD" \
  | grep -oE '(path|file)=[^[:space:]"]+' \
  | head -n1 \
  | sed 's/^[^=]*=//')

TS=$(date -Iseconds 2>/dev/null || date)
printf '%s\t%s\t%s\n' "$TS" "${VERB:-?}" "$KEY_ARG" \
  >> "$VAULT/.obsidian-cli.log" 2>/dev/null || true

# Auto-commit vault changes after mutating obsidian verbs, mirroring the
# Write|Edit PostToolUse hook. The PreToolUse hook only intercepts Bash, so
# agents that write vault pages via `obsidian create/append` (Bash) instead of
# Write/Edit would otherwise miss the auto-commit trigger.
case "${VERB:-}" in
  create|append|prepend|create-or-append|property:set|property:remove|eval)
    [ -d "$VAULT/.git" ] \
      && git -C "$VAULT" add wiki/ .raw/ 2>/dev/null \
      && (git -C "$VAULT" diff --cached --quiet \
           || git -C "$VAULT" commit -m "wiki: auto-commit $(date '+%Y-%m-%d %H:%M')" 2>/dev/null) \
      || true
    ;;
esac

exit 0
