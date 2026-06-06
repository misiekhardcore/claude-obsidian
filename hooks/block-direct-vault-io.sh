#!/usr/bin/env bash
# block-direct-vault-io.sh — PreToolUse hook (matcher: Read|Write|Edit)
#
# Denies direct file-tool access to vault paths so all vault I/O routes through
# the Obsidian CLI (which enforces the vault-open preflight, exit-code
# normalization, and the daily-file race guard). Emits a deny decision with a
# reason that names the correct CLI verb, so the agent self-corrects on the
# next turn without escalating to the user.
#
# Forced exceptions (CLI literally cannot serve these):
#   - _attachments/**             binary files; no CLI binary verb
#   - *.canvas                    content= escape asymmetry corrupts canvas JSON (cli.md §6)
#   - .raw/.manifest.json         incremental JSON mutation via jq + mv
#   - wiki/meta/lint-data-*.json  admin JSON artifact written by lint-scan.sh
#   - .raw/** (Read only)         source documents not indexed by Obsidian
#
# Fail-open: missing jq, unresolvable vault, or unparseable input all exit 0.
# Non-vault sessions and bootstrap states are never disrupted.

set -u

command -v jq >/dev/null 2>&1 || exit 0

INPUT=$(cat)
TOOL_NAME=$(printf '%s' "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)
FILE_PATH=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
[ -z "$TOOL_NAME" ] && exit 0
[ -z "$FILE_PATH" ] && exit 0

PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VAULT=$("${PLUGIN_ROOT}/scripts/resolve-vault.sh" 2>/dev/null) || exit 0
[ -n "$VAULT" ] && [ -d "$VAULT" ] || exit 0

# Fast literal-prefix check first — most file-tool calls in a session target
# paths outside the vault; this short-circuits before spawning realpath twice.
case "$FILE_PATH" in
  "$VAULT"/*) ;;
  *) exit 0 ;;
esac

# Re-check after normalization so paths with ".." segments that escape the
# vault (e.g. "$VAULT/../tmp/foo") don't get falsely blocked. -ms preserves
# symlinks (the vault may live behind a symlink chain).
REAL_VAULT=$(realpath -ms "$VAULT" 2>/dev/null || echo "$VAULT")
REAL_FILE=$(realpath -ms "$FILE_PATH" 2>/dev/null || echo "$FILE_PATH")
case "$REAL_FILE" in
  "$REAL_VAULT"/*) ;;
  *) exit 0 ;;
esac

REL="${REAL_FILE#${REAL_VAULT}/}"

allow() { exit 0; }

case "$TOOL_NAME" in
  Read)
    case "$REL" in
      .raw/*|_attachments/*) allow ;;
      *.canvas)              allow ;;
    esac
    ;;
  Write|Edit)
    case "$REL" in
      _attachments/*)             allow ;;
      *.canvas)                   allow ;;
      .raw/.manifest.json)        allow ;;
      wiki/meta/lint-data-*.json) allow ;;
    esac
    ;;
  *)
    # Unknown tool; we only opted into Read|Write|Edit via the matcher, but be
    # defensive and don't deny anything we weren't asked to police.
    exit 0
    ;;
esac

REASON="Direct ${TOOL_NAME} on vault path '${REL}' is blocked by the claude-obsidian active-enforcement hook. Route this through the Obsidian CLI via Bash so the vault-open preflight, exit-code normalization, and daily-file race guard apply.

Use one of:
  obsidian read path=${REL}                                    (full read)
  obsidian read-head path=${REL} [lines=N]                     (first N lines — saves context)
  obsidian grep path=${REL} pattern=\"...\" [context=N]         (search within file — saves context)
  obsidian create path=${REL} content=\"...\"                  (new pages)
  obsidian create path=${REL} overwrite=true content=\"...\"   (full overwrite, e.g. wiki/hot.md)
  obsidian prepend file=${REL} content=\"...\"                 (prepend, e.g. wiki/index.md, wiki/log.md)
  obsidian append  file=${REL} content=\"...\"                 (append)
  obsidian create-or-append file=${REL} template=\"...\" content=\"...\"  (daily/*.md only — issue #98 guard)
  obsidian property:set name=... value=... path=${REL}        (single frontmatter property)

For cross-file search: obsidian grep-files pattern=\"...\" [dir=wiki]

Documented bypasses (where direct file-tool use is still permitted because the CLI cannot serve them): _attachments/**, *.canvas, .raw/.manifest.json, wiki/meta/lint-data-*.json, and Read on .raw/**. See _shared/vault-ops.md §5."

jq -n --arg r "$REASON" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "deny",
    permissionDecisionReason: $r
  }
}'
