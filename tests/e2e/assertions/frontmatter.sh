#!/usr/bin/env bash
# Assert a file has a frontmatter block (between --- markers) containing
# the required key lines. This is a shape-only check (AC16) — it does not
# validate the YAML body itself; it only verifies the block delimiters and
# the presence of `name:` / `description:` lines.
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

# Check required keys (AC5: name, description)
if echo "$fm" | grep -qE '^name:'; then
  pass "frontmatter has 'name' key"
else
  fail "frontmatter missing 'name' key"
fi

if echo "$fm" | grep -qE '^description:'; then
  pass "frontmatter has 'description' key"
else
  fail "frontmatter missing 'description' key"
fi

echo "  pass=$PASS  fail=$FAIL"
[ "$FAIL" -eq 0 ] || exit 1
