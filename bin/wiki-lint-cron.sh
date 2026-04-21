#!/usr/bin/env bash
# Standalone wiki-lint runner intended for system cron.
#
# One-shot: invokes the lint skill via the `claude` CLI and stamps the lastrun
# marker on success. Exits non-zero on resolve-vault failure (so cron surfaces
# the error in mail/logs); lint-skill output flows through to stdout/stderr.
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

claude -p "Run the wiki-lint skill on $VAULT. Report briefly." || exit $?

date +%s > "$VAULT/.wiki-lint.lastrun"
