#!/usr/bin/env bash
# Smoke tests for scripts/obsidian-cli.sh.
#
# Asserts wrapper output shape and exit-code normalization per _shared/cli.md.
# Runs a representative subset of verbs — exhaustive coverage is the spike's
# job, not the smoke test's.
#
# Usage:
#   bash tests/cli-smoke.sh
#
# Exits non-zero if any assertion fails.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
WRAPPER="$PLUGIN_ROOT/scripts/obsidian-cli.sh"

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

# Pre-flight: wrapper itself must exist and be executable.
if [ ! -x "$WRAPPER" ]; then
  echo "smoke: $WRAPPER missing or not executable" >&2
  exit 2
fi

# Pre-flight: Obsidian must be reachable. If not, exit early with skip.
if ! obsidian version >/dev/null 2>&1; then
  echo "smoke: skipping — obsidian binary unreachable or not running"
  exit 0
fi

echo ""
echo "=== cli-smoke — wrapper output shape and exit codes ==="

# 1. Pure read against an existing wiki file in the active vault.
out=$("$WRAPPER" read path=wiki/hot.md 2>/dev/null); rc=$?
assert_exit 0 "$rc" "read existing file"

# 2. Read a missing file → wrapper exit 1, stdout starts with "Error:".
out=$("$WRAPPER" read path=wiki/__definitely_not_a_file__.md 2>/dev/null); rc=$?
assert_exit 1 "$rc" "read missing file"
assert_contains "$out" "Error: File" "missing-file error pattern"

# 3. Unknown verb → wrapper exit 1.
out=$("$WRAPPER" __not_a_verb__ 2>/dev/null); rc=$?
assert_exit 1 "$rc" "unknown verb"
assert_contains "$out" "Error: Command" "unknown-verb error pattern"

# 4. Read with no args → "No active file" error.
out=$("$WRAPPER" read 2>/dev/null); rc=$?
assert_exit 1 "$rc" "read with no args"
assert_contains "$out" "Error: No active file" "no-active-file error pattern"

# 5. Format-default: backlinks default is tsv (one path per line); json adds wrapping.
out_default=$("$WRAPPER" backlinks path=wiki/index.md 2>/dev/null); rc=$?
assert_exit 0 "$rc" "backlinks default format"

out_json=$("$WRAPPER" backlinks path=wiki/index.md format=json 2>/dev/null); rc=$?
assert_exit 0 "$rc" "backlinks format=json"
# JSON output starts with '[' or '{' — default text does not.
case "$out_json" in
  '['*|'{'*) pass "backlinks format=json — output starts with JSON token" ;;
  *)         fail "backlinks format=json — expected JSON, got: $(echo "$out_json" | head -1)" ;;
esac

# 6. Multiline create → read round-trip (verifies \n escapes round-trip).
SCRATCH="_cli-smoke-scratch"
SCRATCH_DIR="${VAULT:-}"
# Resolve vault path the same way the wrapper does, for cleanup.
SCRATCH_VAULT_PATH="$("$PLUGIN_ROOT/scripts/resolve-vault.sh")"
"$WRAPPER" create "path=$SCRATCH/multiline.md" content="alpha\nbeta\ngamma" overwrite >/dev/null 2>&1
out=$("$WRAPPER" read "path=$SCRATCH/multiline.md" 2>/dev/null); rc=$?
assert_exit 0 "$rc" "read multiline scratch file"
assert_contains "$out" "alpha" "multiline roundtrip — alpha"
assert_contains "$out" "beta"  "multiline roundtrip — beta"
assert_contains "$out" "gamma" "multiline roundtrip — gamma"

# 7. Vault-not-found path: invoke wrapper with a deliberately mangled vault.
# Bypass resolve-vault.sh by calling obsidian directly with a bogus name —
# this exercises the wrapper's error-detection on the literal "Vault not found."
# string. Use a sub-shell with VAULT pointed at a unique name.
out=$(VAULT_OVERRIDE_NAME="__definitely_not_a_vault__" \
      bash -c 'obsidian "vault=__definitely_not_a_vault__" vault 2>/dev/null')
case "$out" in
  "Vault not found."*) pass "wrapper-detectable Vault-not-found stdout pattern present" ;;
  *)                   fail "expected 'Vault not found.' from CLI; got: $(echo "$out" | head -1)" ;;
esac

# Cleanup scratch
if [ -n "$SCRATCH_VAULT_PATH" ] && [ -d "$SCRATCH_VAULT_PATH/$SCRATCH" ]; then
  rm -rf "$SCRATCH_VAULT_PATH/$SCRATCH"
fi

echo ""
echo "=== summary ==="
echo "  pass=$PASS  fail=$FAIL"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
