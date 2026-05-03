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
echo "=== wrapper-only verbs — create-or-append, frontmatter-set ==="

# Per-process scratch keeps parallel runs (and re-runs) from colliding;
# `obsidian create` creates intermediate directories on first write.
VERB_SCRATCH="_cli-smoke-verbs-$$"
verb_path="$VERB_SCRATCH/coa.md"
template='---\ntype: daily\ndate: 2026-05-03\ncreated: 2026-05-03\nupdated: 2026-05-03\n---\n\n## Captures\n'

# 1. create-or-append, file missing → create+append branch.
out=$("$WRAPPER" create-or-append "file=$verb_path" "template=$template" "content=- 09:00 first"); rc=$?
assert_exit 0 "$rc" "create-or-append (missing) exit"
case "$out" in "Created and appended:"*) pass "create-or-append (missing) output shape" ;;
               *)                          fail "create-or-append (missing) — got: $out" ;; esac

# 2. create-or-append, file exists → append-only branch.
out=$("$WRAPPER" create-or-append "file=$verb_path" "template=$template" "content=- 09:01 second"); rc=$?
assert_exit 0 "$rc" "create-or-append (exists) exit"
case "$out" in "Appended to:"*) pass "create-or-append (exists) output shape" ;;
               *)               fail "create-or-append (exists) — got: $out" ;; esac

# 3. Both bullets must survive the second call (the #98 regression check).
body=$("$WRAPPER" read "path=$verb_path" 2>/dev/null)
assert_contains "$body" "- 09:00 first"  "create-or-append — first bullet preserved"
assert_contains "$body" "- 09:01 second" "create-or-append — second bullet appended"
assert_contains "$body" "## Captures"    "create-or-append — heading preserved"

# 4. frontmatter-set replace existing key.
out=$("$WRAPPER" frontmatter-set "path=$verb_path" key=updated value=2026-05-04); rc=$?
assert_exit 0 "$rc" "frontmatter-set replace exit"
case "$out" in "Set frontmatter:"*) pass "frontmatter-set replace output" ;;
               *)                   fail "frontmatter-set replace — got: $out" ;; esac
body=$("$WRAPPER" read "path=$verb_path" 2>/dev/null)
assert_contains "$body" "updated: 2026-05-04" "frontmatter-set — value rewritten"
assert_contains "$body" "- 09:00 first"        "frontmatter-set — body bullet preserved (1)"
assert_contains "$body" "- 09:01 second"       "frontmatter-set — body bullet preserved (2)"

# 5. frontmatter-set insert-if-missing.
out=$("$WRAPPER" frontmatter-set "path=$verb_path" key=tags value=daily); rc=$?
assert_exit 0 "$rc" "frontmatter-set insert exit"
body=$("$WRAPPER" read "path=$verb_path" 2>/dev/null)
assert_contains "$body" "tags: daily" "frontmatter-set — key inserted"
# Must land *inside* the frontmatter block, before the closing ---.
fm_block=$(printf '%s\n' "$body" | awk 'NR==1 && $0=="---"{p=1; next} p && $0=="---"{exit} p{print}')
case "$fm_block" in *"tags: daily"*) pass "frontmatter-set — key inserted inside frontmatter block" ;;
                    *)               fail "frontmatter-set — key landed outside frontmatter block" ;; esac

# 6. frontmatter-set on a file with no frontmatter → exit 1.
nofm_path="$VERB_SCRATCH/no-frontmatter-$$.md"
"$WRAPPER" create "path=$nofm_path" content="just a body line" overwrite >/dev/null 2>&1
out=$("$WRAPPER" frontmatter-set "path=$nofm_path" key=updated value=2026-05-04 2>&1); rc=$?
assert_exit 1 "$rc" "frontmatter-set malformed (no frontmatter) exit"
case "$out" in *"no frontmatter block"*) pass "frontmatter-set malformed — error message" ;;
               *)                         fail "frontmatter-set malformed — expected 'no frontmatter block'; got: $out" ;; esac

# Cleanup verb scratch
if [ -n "$SCRATCH_VAULT_PATH" ] && [ -d "$SCRATCH_VAULT_PATH/$VERB_SCRATCH" ]; then
  rm -rf "$SCRATCH_VAULT_PATH/$VERB_SCRATCH"
fi

echo ""
echo "=== rewrite-hook — PreToolUse Bash auto-rewrite ==="

REWRITE_HOOK="$PLUGIN_ROOT/hooks/obsidian-cli-rewrite.sh"

# Helper: run hook with a given command, return its stdout. `jq -Rs` slurps
# stdin as a single raw string so multi-line commands round-trip correctly
# (plain `-R` would emit one JSON string per line and break the wrapping JSON).
run_hook() {
  local cmd="$1"
  printf '%s' "{\"tool_input\":{\"command\":$(printf '%s' "$cmd" | jq -Rs .)}}" | bash "$REWRITE_HOOK"
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

# 6. Multi-line `obsidian create \ ...` must rewrite the leading token only and
#    preserve continuation lines verbatim. Regression guard: a previous
#    implementation used `read -r FIRST REST` which dropped everything after
#    the first newline, silently truncating multi-line invocations from skills.
multiline_cmd=$'obsidian create \\\n  path=wiki/foo.md \\\n  content="alpha\\nbeta"'
out=$(run_hook "$multiline_cmd")
rewritten=$(echo "$out" | jq -r '.hookSpecificOutput.updatedInput.command // empty')
if [ -n "$rewritten" ] \
   && echo "$rewritten" | head -n1 | grep -qF '"${CLAUDE_PLUGIN_ROOT}/scripts/obsidian-cli.sh" create' \
   && echo "$rewritten" | grep -qF 'path=wiki/foo.md' \
   && echo "$rewritten" | grep -qF 'content="alpha'; then
  pass "multi-line rewrite preserves continuation lines"
else
  fail "expected multi-line rewrite to keep path/content args; got: $(printf '%s' "$rewritten" | head -c 200)"
fi

echo ""
echo "=== rewrite-hook — daily/*.md antipattern guard (#98) ==="

# 1. `obsidian create overwrite=true path=daily/...` must be rejected.
out=$(run_hook 'obsidian create path=daily/2026-05-03.md overwrite=true content="full file body"')
if echo "$out" | jq -e '.hookSpecificOutput.permissionDecision == "deny"' >/dev/null 2>&1; then
  pass "daily/*.md overwrite=true — denied"
else
  fail "daily/*.md overwrite=true — expected deny; got: $(echo "$out" | jq -c '.hookSpecificOutput // "<none>"')"
fi

# 2. `obsidian create overwrite path=daily/...` (flag form) must be rejected.
out=$(run_hook 'obsidian create path=daily/2026-05-03.md content="x" overwrite')
if echo "$out" | jq -e '.hookSpecificOutput.permissionDecision == "deny"' >/dev/null 2>&1; then
  pass "daily/*.md bare overwrite — denied"
else
  fail "daily/*.md bare overwrite — expected deny; got: $(echo "$out" | jq -c '.hookSpecificOutput // "<none>"')"
fi

# 3. `obsidian create path=daily/...` WITHOUT overwrite must NOT be denied
#    (legitimate first-time create through the rewrite path).
out=$(run_hook 'obsidian create path=daily/2026-05-03.md content="fresh"')
decision=$(echo "$out" | jq -r '.hookSpecificOutput.permissionDecision // empty' 2>/dev/null)
if [ "$decision" != "deny" ]; then
  pass "daily/*.md create (no overwrite) — not denied"
else
  fail "daily/*.md create (no overwrite) — unexpectedly denied"
fi

# 4. `obsidian create overwrite=true path=wiki/...` must NOT be denied
#    (legitimate full-rewrite outside daily/).
out=$(run_hook 'obsidian create path=wiki/index.md overwrite=true content="x"')
decision=$(echo "$out" | jq -r '.hookSpecificOutput.permissionDecision // empty' 2>/dev/null)
if [ "$decision" != "deny" ]; then
  pass "wiki/*.md overwrite=true — not denied (legit full-rewrite)"
else
  fail "wiki/*.md overwrite=true — unexpectedly denied"
fi

# 5. `obsidian create-or-append file=daily/...` must NOT be denied (the verb
#    that replaces the antipattern).
out=$(run_hook 'obsidian create-or-append file=daily/2026-05-03.md template="..." content="- 09:00 x"')
decision=$(echo "$out" | jq -r '.hookSpecificOutput.permissionDecision // empty' 2>/dev/null)
if [ "$decision" != "deny" ]; then
  pass "daily/*.md create-or-append — not denied"
else
  fail "daily/*.md create-or-append — unexpectedly denied"
fi

echo ""
echo "=== summary ==="
echo "  pass=$PASS  fail=$FAIL"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
