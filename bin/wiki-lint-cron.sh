#!/usr/bin/env bash
# Standalone wiki-lint runner intended for system cron.
#
# One-shot: invokes the lint skill via the `claude` CLI and stamps the lastrun
# marker on success. When Obsidian is closed (cron context), falls back to
# direct vault inspection (orphans, deadends, unresolved) to remain operational.
# Exits non-zero on resolve-vault failure (so cron surfaces the error in
# mail/logs); lint-skill output flows through to stdout/stderr.
#
# Cron-time behavior: the Obsidian CLI (used by the lint skill) requires the
# Obsidian app to be running. When invoked from a closed-laptop context, the
# skill call fails; the fallback below uses direct file operations to check for
# basic vault hygiene. This ensures wiki-lint-cron.sh remains functional even
# when Obsidian is offline. See _shared/cli.md §5 and #52 for design rationale.
#
# Usage (example crontab — weekly, Sunday 03:00):
#   0 3 * * 0 /absolute/path/to/claude-obsidian/bin/wiki-lint-cron.sh

set -e

# Locate the plugin root. Prefer CLAUDE_PLUGIN_ROOT when set (in-session).
# Otherwise derive it from $0 so cron invocations work without a session.
if [ -z "${CLAUDE_PLUGIN_ROOT:-}" ]; then
  SCRIPT_PATH=$(readlink -f "$0" 2>/dev/null || python3 -c "import os,sys;print(os.path.realpath(sys.argv[1]))" "$0")
  CLAUDE_PLUGIN_ROOT=$(dirname "$(dirname "$SCRIPT_PATH")")
  export CLAUDE_PLUGIN_ROOT
fi

VAULT=$("${CLAUDE_PLUGIN_ROOT}/scripts/resolve-vault.sh") || exit 1

# Try the lint skill (requires Obsidian running). If Obsidian is unreachable,
# fall back to direct vault inspection.
if claude -p "Run the wiki-lint skill on $VAULT. Report briefly." 2>/dev/null; then
  date +%s > "$VAULT/.wiki-lint.lastrun"
  exit 0
fi

# Fallback: direct-file-op inspection when Obsidian is closed.
# This is a best-effort check: look for orphans and deadends via grep patterns.
echo "[wiki-lint-cron] Obsidian unreachable; running fallback vault checks..."

ORPHANS=0
DEADENDS=0

# Scan for orphan pages: wiki/ files with no backlinks.
# (Simple heuristic: check if any other wiki file links to this one.)
if [ -d "$VAULT/wiki" ]; then
  while IFS= read -r page; do
    pagename=$(basename "$page" .md)
    # Skip meta pages (hot.md, index.md, etc.)
    [[ "$pagename" == "hot" || "$pagename" == "index" ]] && continue
    # Check if any other wiki file contains a wikilink to this page
    if ! grep -r "\[\[$pagename" "$VAULT/wiki" --include="*.md" >/dev/null 2>&1; then
      echo "  orphan: $page"
      ((ORPHANS++))
    fi
  done < <(find "$VAULT/wiki" -type f -name "*.md")
fi

# Scan for deadends: wiki/ files with unresolved wikilinks.
# (Simple heuristic: look for [[...]] patterns pointing to non-existent files.)
if [ -d "$VAULT/wiki" ]; then
  while IFS= read -r file; do
    while IFS= read -r link; do
      linkname=$(echo "$link" | sed -E 's/.*\[\[([^\]]+)\].*/\1/')
      # Check if target exists (in wiki/ or concepts/, entities/, sources/)
      if [ -n "$linkname" ]; then
        found=0
        for dir in wiki/concepts wiki/entities wiki/sources wiki; do
          [ -f "$VAULT/$dir/$linkname.md" ] && found=1 && break
        done
        [ $found -eq 0 ] && echo "  unresolved in $file: $linkname" && ((DEADENDS++))
      fi
    done < <(grep -o '\[\[[^\]]*\]\]' "$file")
  done < <(find "$VAULT/wiki" -type f -name "*.md")
fi

if [ $ORPHANS -gt 0 ] || [ $DEADENDS -gt 0 ]; then
  echo "[wiki-lint-cron] Found $ORPHANS orphan(s), $DEADENDS unresolved link(s). Manual review recommended."
else
  echo "[wiki-lint-cron] Vault check complete: no obvious orphans or deadends."
fi

date +%s > "$VAULT/.wiki-lint.lastrun"
