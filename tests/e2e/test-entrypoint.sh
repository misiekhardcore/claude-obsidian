#!/usr/bin/env bash
# Shared test helpers for E2E assertion scripts.
# Source this file; do not execute it directly.
#
# Provides: PASS/FAIL counters, pass(), fail(), assert_exit(),
# assert_contains(), assert_file_exists().
# Pattern matches tests/cli-smoke.sh and tests/test-seed-demo.sh.

PASS=0
FAIL=0

pass() { echo "  [ok] $1"; PASS=$((PASS + 1)); }
fail() { echo "  [FAIL] $1"; FAIL=$((FAIL + 1)); }

# assert_exit <expected> <actual> <label>
assert_exit() {
  local expected="$1" actual="$2" label="$3"
  if [ "$actual" -eq "$expected" ]; then
    pass "$label — exit=$actual"
  else
    fail "$label — exit=$actual (expected $expected)"
  fi
}

# assert_contains <output> <pattern> <label>
assert_contains() {
  local out="$1" pat="$2" label="$3"
  if echo "$out" | grep -qF -- "$pat"; then
    pass "$label — contains '$pat'"
  else
    fail "$label — missing '$pat'; got:"
    echo "$out" | head -3 | sed 's/^/      /'
  fi
}

# assert_file_exists <path> [label]
assert_file_exists() {
  local path="$1" label="${2:-$1}"
  if [ -e "$path" ]; then
    pass "$label — exists"
  else
    fail "$label — not found: $path"
  fi
}
