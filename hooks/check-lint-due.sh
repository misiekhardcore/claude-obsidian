#!/usr/bin/env bash
# SessionStart hook: suggest running wiki-lint when last run is older than the
# configured cadence. Output goes into session context as a soft nudge — not a
# blocking request. Intentionally silent when the vault is not configured, the
# wiki/ directory does not exist, or the marker is fresh.

set -e

VAULT=$("${CLAUDE_PLUGIN_ROOT}/scripts/resolve-vault.sh") 2>/dev/null || exit 0
[ -d "$VAULT/wiki" ] || exit 0

MARKER="$VAULT/.wiki-lint.lastrun"
INTERVAL_DAYS=${WIKI_LINT_INTERVAL_DAYS:-7}
NOW=$(date +%s)

if [ -f "$MARKER" ]; then
  LAST=$(cat "$MARKER" 2>/dev/null || echo 0)
else
  LAST=0
fi

# Guard against non-numeric marker contents
case "$LAST" in
  '' | *[!0-9]*) LAST=0 ;;
esac

AGE_DAYS=$(( (NOW - LAST) / 86400 ))

if [ "$AGE_DAYS" -lt "$INTERVAL_DAYS" ]; then
  exit 0
fi

cat <<EOF
WIKI_LINT_DUE: Last wiki-lint ran ${AGE_DAYS} days ago (cadence: every ${INTERVAL_DAYS}d).

When convenient during this session — especially if no urgent task is in flight —
run the wiki-lint skill to scan for orphan pages, dead wikilinks, stale claims,
and missing cross-references. After it completes, record the run by writing the
current timestamp to the marker:

  date +%s > "$VAULT/.wiki-lint.lastrun"

This is a soft nudge, not a blocking request. Skip silently if the user is
mid-task.
EOF
