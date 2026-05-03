#!/usr/bin/env bash
# Assert today's daily file has required shape per AC6.
# Usage: bash daily-shape.sh <vault_path>
# Exits non-zero if any assertion fails.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../test-entrypoint.sh
source "$SCRIPT_DIR/../test-entrypoint.sh"

VAULT="${1:-}"
if [ -z "$VAULT" ]; then
  echo "Usage: daily-shape.sh <vault_path>" >&2
  exit 2
fi

TODAY=$(date +%F)
DAILY_FILE="$VAULT/daily/$TODAY.md"

echo "=== daily-shape: $DAILY_FILE ==="

assert_file_exists "$DAILY_FILE" "daily/$TODAY.md"

if [ "$FAIL" -gt 0 ]; then
  echo "  pass=$PASS  fail=$FAIL"
  exit 1
fi

# Check ## Captures header (AC6)
if grep -qE '^## Captures' "$DAILY_FILE"; then
  pass "## Captures section present"
else
  fail "## Captures section missing"
fi

# Count bullet lines under ## Captures, stopping at the next ## section (AC6: ≥3)
BULLET_COUNT=$(awk \
  '/^## Captures/{p=1;next} /^## /{p=0} p && /^- /{c++} END{print c+0}' \
  "$DAILY_FILE")

if [ "$BULLET_COUNT" -ge 3 ]; then
  pass "≥3 bullets under ## Captures (found $BULLET_COUNT)"
else
  fail "expected ≥3 bullets under ## Captures; found $BULLET_COUNT"
fi

echo "  pass=$PASS  fail=$FAIL"
[ "$FAIL" -eq 0 ] || exit 1
