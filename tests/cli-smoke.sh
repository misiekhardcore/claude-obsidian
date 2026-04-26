#!/usr/bin/env bash
# Smoke tests for scripts/obsidian-cli.sh.
#
# Asserts wrapper output shape and exit-code normalization. Exit-code
# semantics, error-pattern detection, escape-hatch policy, and the documented
# bypasses are described in the wrapper's header comment — this script
# enforces them. Runs a representative subset of verbs; exhaustive coverage is
# the spike's job, not the smoke's.
#
# Vault: runs against whatever vault is currently active in Obsidian (via
# scripts/resolve-vault.sh). Assertions are deliberately content-agnostic —
# the smoke verifies wrapper *contract* (exit codes, error patterns, format
# negotiation, multiline round-trip), not fixture-specific assertions.
# tests/fixtures/vault/ is committed as a stable test corpus for downstream
# skill-conversion smoke tests; registering it with Obsidian for use here is
# left to those follow-ups (the desktop CLI requires the target vault to be
# registered, which can't be done non-interactively without manipulating
# Obsidian's config file).
#
# ─── Format defaults per verb ────────────────────────────────────────────────
# The wrapper does NOT rewrite format= arguments. Skills consuming structured
# output must opt in explicitly. Verified empirically against CLI 1.12.7 by
# scripts/cli-spike.sh; captures in tests/spike-results/.
#
#   Verb         Has format=?      Default   Skills should request
#   ----------   --------------    -------   --------------------------------
#   backlinks    json|tsv|csv      tsv       format=json
#   tags         json|tsv|csv      tsv       format=json
#   unresolved   json|tsv|csv      tsv       format=json
#   bookmarks    json|tsv|csv      tsv       format=json
#   outline      tree|md|json      tree      format=json
#   search       text|json         text      format=json (or text for grep)
#   aliases      —                 text      text — no JSON option
#   orphans      —                 text      text — one path per line
#   deadends     —                 text      text — one path per line
#   tasks        —                 text      text — no JSON option
#   properties   —                 text      text — no JSON option
#   read         —                 raw body  raw bytes
#
# Empirical correction vs. the original epic plan: orphans, deadends, tasks,
# and properties do NOT accept format=json. The wrapper does not synthesize
# JSON for verbs the CLI does not natively format.
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
echo "=== rewrite-hook — PreToolUse Bash auto-rewrite ==="

REWRITE_HOOK="$PLUGIN_ROOT/hooks/obsidian-cli-rewrite.sh"

# Helper: run hook with a given command, return its stdout.
run_hook() {
  local cmd="$1"
  printf '%s' "{\"tool_input\":{\"command\":$(printf '%s' "$cmd" | jq -R .)}}" | bash "$REWRITE_HOOK"
}

# 1. Raw `obsidian read` should be rewritten to the wrapper.
out=$(run_hook "obsidian read path=wiki/hot.md")
if echo "$out" | jq -e '.hookSpecificOutput.updatedInput.command | contains("obsidian-cli.sh") and contains("read path=wiki/hot.md")' >/dev/null 2>&1; then
  pass "raw obsidian → wrapper rewrite emitted"
else
  fail "expected updatedInput.command to contain wrapper path; got: $(echo "$out" | jq -c '.hookSpecificOutput.updatedInput.command // "<none>"')"
fi

# 2. Already-wrapped commands must pass through unchanged (no JSON output).
out=$(run_hook "scripts/obsidian-cli.sh read path=wiki/hot.md")
if [ -z "$out" ]; then
  pass "already-wrapped command — pass-through (no rewrite)"
else
  fail "expected pass-through; got: $out"
fi

# 3. `which obsidian` must NOT be rewritten (first token is `which`).
out=$(run_hook "which obsidian")
if [ -z "$out" ]; then
  pass "which obsidian — pass-through (first token is which)"
else
  fail "expected pass-through for which obsidian; got: $out"
fi

# 4. `pgrep -f obsidian` must NOT be rewritten.
out=$(run_hook "pgrep -f obsidian")
if [ -z "$out" ]; then
  pass "pgrep -f obsidian — pass-through"
else
  fail "expected pass-through for pgrep; got: $out"
fi

# 5. `obsidian version` should be rewritten.
out=$(run_hook "obsidian version")
if echo "$out" | jq -e '.hookSpecificOutput.updatedInput.command | endswith("version")' >/dev/null 2>&1; then
  pass "obsidian version — rewritten"
else
  fail "obsidian version — expected rewrite ending with 'version'"
fi

echo ""
echo "=== summary ==="
echo "  pass=$PASS  fail=$FAIL"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
