#!/usr/bin/env bash
# Copy the plugin's _templates/*.md into $VAULT/_templates/, skipping any
# files that already exist (idempotent).
#
# Usage: bin/copy-templates.sh /absolute/path/to/vault

set -euo pipefail

if [ -z "${1:-}" ]; then
  echo "Error: vault path is required" >&2
  echo "Usage: bin/copy-templates.sh /absolute/path/to/vault" >&2
  exit 1
fi

VAULT="$1"

# Locate the plugin root. Prefer CLAUDE_PLUGIN_ROOT when set (in-session).
# Otherwise derive it from $0 so standalone invocations work.
if [ -z "${CLAUDE_PLUGIN_ROOT:-}" ]; then
  SCRIPT_PATH=$(readlink -f "$0" 2>/dev/null || python3 -c "import os,sys;print(os.path.realpath(sys.argv[1]))" "$0")
  CLAUDE_PLUGIN_ROOT=$(dirname "$(dirname "$SCRIPT_PATH")")
  export CLAUDE_PLUGIN_ROOT
fi

SRC_DIR="${CLAUDE_PLUGIN_ROOT}/_templates"
DST_DIR="${VAULT}/_templates"

mkdir -p "$DST_DIR"

for src in "$SRC_DIR"/*.md; do
  [ -e "$src" ] || continue
  dst="$DST_DIR/$(basename "$src")"
  [ -e "$dst" ] || cp "$src" "$dst"
done
