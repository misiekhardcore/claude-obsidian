#!/usr/bin/env bash
# Assert a file has a frontmatter block (between --- markers) containing
# the universal required keys per `_shared/frontmatter.md`. Shape-only
# (AC16) — verifies the block delimiters and the presence of `title:` and
# `type:` lines, which every wiki page must carry.
# Usage: bash frontmatter.sh <file>
# Exits non-zero if any assertion fails. AC5.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../test-entrypoint.sh
source "$SCRIPT_DIR/../test-entrypoint.sh"

FILE="${1:-}"
if [ -z "$FILE" ]; then
  echo "Usage: frontmatter.sh <file>" >&2
  exit 2
fi

echo "=== frontmatter: $FILE ==="

assert_file_exists "$FILE" "target file"

if [ "$FAIL" -gt 0 ]; then
  echo "  pass=$PASS  fail=$FAIL"
  exit 1
fi

# Extract content between first and second --- markers
fm=$(awk '/^---/{c++; if(c==1){p=1;next}; if(c==2){exit}} p{print}' "$FILE")

if [ -n "$fm" ]; then
  pass "frontmatter block present"
else
  fail "frontmatter block missing or empty"
  echo "  pass=$PASS  fail=$FAIL"
  exit 1
fi

# Check universal required keys per _shared/frontmatter.md (AC5).
if echo "$fm" | grep -qE '^title:'; then
  pass "frontmatter has 'title' key"
else
  fail "frontmatter missing 'title' key"
fi

if echo "$fm" | grep -qE '^type:'; then
  pass "frontmatter has 'type' key"
else
  fail "frontmatter missing 'type' key"
fi

# On any failure, dump the frontmatter so the failure reason is obvious.
if [ "$FAIL" -gt 0 ]; then
  echo "  --- frontmatter block as parsed ---" >&2
  printf '%s\n' "$fm" | sed 's/^/  | /' >&2
fi

echo "  pass=$PASS  fail=$FAIL"
[ "$FAIL" -eq 0 ] || exit 1
