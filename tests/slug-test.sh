#!/usr/bin/env bash
# Tests for scripts/slug.sh.
#
# Pins the slug-rule acceptance criteria from issue #61. Each assertion maps
# to a numbered AC where applicable.
#
# Usage:
#   bash tests/slug-test.sh
#
# Exits non-zero if any assertion fails.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SLUG="$PLUGIN_ROOT/scripts/slug.sh"

PASS=0
FAIL=0

pass() { echo "  [ok] $1"; PASS=$((PASS + 1)); }
fail() { echo "  [FAIL] $1"; FAIL=$((FAIL + 1)); }

# assert_eq <expected> <actual> <label>
assert_eq() {
  local expected="$1" actual="$2" label="$3"
  if [ "$actual" = "$expected" ]; then
    pass "$label"
  else
    fail "$label — got '$actual', expected '$expected'"
  fi
}

# assert_exit <expected> <actual> <label>
assert_exit() {
  local expected="$1" actual="$2" label="$3"
  if [ "$actual" -eq "$expected" ]; then
    pass "$label — exit=$actual"
  else
    fail "$label — exit=$actual (expected $expected)"
  fi
}

if [ ! -x "$SLUG" ]; then
  echo "slug-test: $SLUG missing or not executable" >&2
  exit 2
fi

echo ""
echo "=== slug-test — slug.sh contract ==="

# AC1 — title-driven slug, simple case.
out=$(bash "$SLUG" "Fix flaky CI runner")
assert_eq "fix-flaky-ci-runner" "$out" "AC1: simple title slugifies"

# AC2 — slug ≤ 40 chars: used whole, no truncation.
out=$(bash "$SLUG" "Short title under forty chars")
assert_eq "short-title-under-forty-chars" "$out" "AC2: ≤40 chars used whole"

# AC3a — slug > 40 chars: word-boundary truncation at last "-" before char 40.
# Input slug "claude-workflow-uses-git-cli-instead-of-wt-for-worktrees" (56 chars)
# Char-40 head is "claude-workflow-uses-git-cli-instead-of-" (ends with -);
# stripping shortest "-*" leaves "claude-workflow-uses-git-cli-instead-of" (39).
out=$(bash "$SLUG" "claude-workflow uses git CLI instead of wt for worktrees")
assert_eq "claude-workflow-uses-git-cli-instead-of" "$out" "AC3a: word-boundary truncation"
[ "${#out}" -le 40 ] && pass "AC3a: result ≤ 40 chars (${#out})" \
                    || fail "AC3a: result > 40 chars (${#out})"

# AC3b — first word ≥ 40 chars, no "-" before char 40: hard-truncated at 40.
out=$(bash "$SLUG" "abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz")
assert_eq "abcdefghijklmnopqrstuvwxyzabcdefghijklmn" "$out" "AC3b: hard-truncate when no word break"
[ "${#out}" -eq 40 ] && pass "AC3b: result is exactly 40 chars" \
                    || fail "AC3b: result is ${#out} chars (expected 40)"

# AC5a — title slugifies to empty, body fallback used.
out=$(bash "$SLUG" "!@#\$%^&*()" "fallback content from body")
assert_eq "fallback-content-from-body" "$out" "AC5a: empty-title falls back to body slug"

# AC5b — title and body both slugify to empty: exit 1.
out=$(bash "$SLUG" "!@#" "***" 2>/dev/null); rc=$?
assert_exit 1 "$rc" "AC5b: both empty → exit 1"

# AC8 — leading/trailing whitespace trimmed before slugifying (no leading/trailing "-").
out=$(bash "$SLUG" "  Foo Bar  ")
assert_eq "foo-bar" "$out" "AC8: leading/trailing whitespace trimmed"

# Collapse runs of separators.
out=$(bash "$SLUG" "foo!!!bar???baz")
assert_eq "foo-bar-baz" "$out" "collapse: runs of non-alphanumerics → single -"

# Mixed case lowercased.
out=$(bash "$SLUG" "Hello World")
assert_eq "hello-world" "$out" "lowercase: mixed case → lowercase"

# Argument validation: zero args → exit 2.
out=$(bash "$SLUG" 2>/dev/null); rc=$?
assert_exit 2 "$rc" "no args → exit 2"

# Argument validation: too many args → exit 2.
out=$(bash "$SLUG" a b c 2>/dev/null); rc=$?
assert_exit 2 "$rc" "three args → exit 2"

echo ""
echo "=== slug-test summary ==="
echo "  passed: $PASS"
echo "  failed: $FAIL"
[ "$FAIL" -eq 0 ]
