#!/usr/bin/env bash
# Assert vault has the required dirs and key files per AC4.
# Usage: bash vault-shape.sh <vault_path>
# Exits non-zero if any assertion fails.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../test-entrypoint.sh
source "$SCRIPT_DIR/../test-entrypoint.sh"

VAULT="${1:-}"
if [ -z "$VAULT" ]; then
  echo "Usage: vault-shape.sh <vault_path>" >&2
  exit 2
fi

echo "=== vault-shape: $VAULT ==="

# Key files (AC4)
assert_file_exists "$VAULT/wiki/hot.md"   "wiki/hot.md"
assert_file_exists "$VAULT/wiki/index.md" "wiki/index.md"

# Required directories (AC4)
for dir in wiki/concepts wiki/entities wiki/sources notes daily .raw _templates; do
  assert_file_exists "$VAULT/$dir" "$dir/"
done

echo "  pass=$PASS  fail=$FAIL"
[ "$FAIL" -eq 0 ] || exit 1
