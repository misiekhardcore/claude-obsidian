#!/usr/bin/env bash
# Assert a named section header exists in a file and has ≥1 non-blank body line.
# Usage: bash section-header.sh <file> <header>
# Example: bash section-header.sh daily/2024-01-01.md "## Summary"
# Exits non-zero if any assertion fails. AC7.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../test-entrypoint.sh
source "$SCRIPT_DIR/../test-entrypoint.sh"

FILE="${1:-}"
HEADER="${2:-}"
if [ -z "$FILE" ] || [ -z "$HEADER" ]; then
  echo "Usage: section-header.sh <file> <header>" >&2
  exit 2
fi

echo "=== section-header: '$HEADER' in $FILE ==="

assert_file_exists "$FILE" "target file"

if [ "$FAIL" -gt 0 ]; then
  echo "  pass=$PASS  fail=$FAIL"
  exit 1
fi

# Check header exists
if grep -qF "$HEADER" "$FILE"; then
  pass "section header '$HEADER' present"
else
  fail "section header '$HEADER' missing"
  echo "  pass=$PASS  fail=$FAIL"
  exit 1
fi

# Check ≥1 non-blank line follows the header, before the next ## section
NONBLANK=$(awk -v hdr="$HEADER" \
  '$0==hdr{p=1;next} p && /^## /{exit} p && NF>0{found=1;exit} END{print found+0}' \
  "$FILE")

if [ "$NONBLANK" -eq 1 ]; then
  pass "section '$HEADER' has ≥1 non-blank body line"
else
  fail "section '$HEADER' has no non-blank body (empty section or missing)"
fi

echo "  pass=$PASS  fail=$FAIL"
[ "$FAIL" -eq 0 ] || exit 1
