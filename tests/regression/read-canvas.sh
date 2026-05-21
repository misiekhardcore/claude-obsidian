#!/usr/bin/env bash
# read-canvas.sh — deterministic unit tests for scripts/read-canvas.sh.
#
# Tests:
#   1. Missing argument → exit 1
#   2. Non-existent file → exit 2
#   3. Malformed JSON → exit 3
#   4. Stripped output: no layout fields (x, y, width, height, id) in output
#   5. Groups rendered as ## sections in top-to-bottom order
#   6. Ungrouped nodes emitted under ## (ungrouped)
#   7. Edges rendered as "from → to" list with optional label
#   8. File/link node types rendered with [file]/[link] prefix
#   9. --raw flag: output is valid JSON containing layout fields
#  10. --raw flag: unknown flags → exit 1
#  11. --raw flag: missing file still → exit 2
#
# Does NOT require Obsidian. Runs entirely from tests/fixtures/sample.canvas.
#
# Usage:
#   bash tests/regression/read-canvas.sh
#
# Exits 0 on pass, 1 on any assertion failure.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SCRIPT="$PLUGIN_ROOT/scripts/read-canvas.sh"
FIXTURE="$PLUGIN_ROOT/tests/fixtures/sample.canvas"

PASS=0
FAIL=0

pass() { echo "  [ok] $1"; PASS=$((PASS + 1)); }
fail() { echo "  [FAIL] $1"; FAIL=$((FAIL + 1)); }

assert_exit() {
  local expected="$1" actual="$2" label="$3"
  if [ "$actual" -eq "$expected" ]; then
    pass "$label — exit=$actual"
  else
    fail "$label — exit=$actual (expected $expected)"
  fi
}

assert_contains() {
  local out="$1" pat="$2" label="$3"
  if printf '%s\n' "$out" | grep -qF -- "$pat"; then
    pass "$label — contains '$pat'"
  else
    fail "$label — missing '$pat'; got:\n$(printf '%s\n' "$out" | head -5 | sed 's/^/      /')"
  fi
}

assert_not_contains() {
  local out="$1" pat="$2" label="$3"
  if printf '%s\n' "$out" | grep -qF -- "$pat"; then
    fail "$label — unexpectedly contains '$pat'"
  else
    pass "$label — does not contain '$pat'"
  fi
}

if [ ! -x "$SCRIPT" ]; then
  echo "read-canvas: $SCRIPT missing or not executable" >&2
  exit 2
fi

if [ ! -f "$FIXTURE" ]; then
  echo "read-canvas: fixture missing: $FIXTURE" >&2
  exit 2
fi

echo ""
echo "=== read-canvas — error handling ==="

# 1. Missing argument → exit 1
out=$("$SCRIPT" 2>&1) || rc=$?; rc=${rc:-0}
assert_exit 1 "$rc" "no args"
assert_contains "$out" "Usage:" "no-args usage hint"

# 2. Non-existent file → exit 2
out=$("$SCRIPT" /nonexistent/path/to/canvas.canvas 2>&1) || rc=$?; rc=${rc:-0}
assert_exit 2 "$rc" "nonexistent file"
assert_contains "$out" "Error: file not found" "nonexistent-file error message"

# 3. Malformed JSON → exit 3
MALFORMED_FILE="$(mktemp /tmp/read-canvas-test-XXXXXX.canvas)"
printf '{not valid json' > "$MALFORMED_FILE"
out=$("$SCRIPT" "$MALFORMED_FILE" 2>&1) || rc=$?; rc=${rc:-0}
assert_exit 3 "$rc" "malformed JSON"
assert_contains "$out" "Error: failed to parse" "malformed-JSON error message"
rm -f "$MALFORMED_FILE"

echo ""
echo "=== read-canvas — stripped output ==="

out=$("$SCRIPT" "$FIXTURE")

# 4. Layout fields must not appear in stripped output
for field in '"x"' '"y"' '"width"' '"height"' '"id"'; do
  assert_not_contains "$out" "$field" "stripped output — no $field"
done

# 5. Groups rendered as ## sections
assert_contains "$out" "## Planning"   "group Planning as ## section"
assert_contains "$out" "## Execution"  "group Execution as ## section"

# Check top-to-bottom ordering: Planning (y=0) must appear before Execution (y=500)
planning_line=$(printf '%s\n' "$out" | grep -n "## Planning"  | head -1 | cut -d: -f1)
execution_line=$(printf '%s\n' "$out" | grep -n "## Execution" | head -1 | cut -d: -f1)
if [ -n "$planning_line" ] && [ -n "$execution_line" ] && [ "$planning_line" -lt "$execution_line" ]; then
  pass "groups ordered top-to-bottom (Planning before Execution)"
else
  fail "groups not in top-to-bottom order (Planning=$planning_line, Execution=$execution_line)"
fi

# Node text content rendered inside their group section
assert_contains "$out" "Ideation"              "Planning group — Ideation text"
assert_contains "$out" "Scope the work"        "Planning group — scoping text"
assert_contains "$out" "Implement each task"   "Execution group — implementation text"
assert_contains "$out" "Review and ship"       "Execution group — review text"

# 6. Ungrouped nodes under ## (ungrouped)
assert_contains "$out" "## (ungrouped)"            "ungrouped section present"
assert_contains "$out" "[file] wiki/concepts/spec" "file node rendered"
assert_contains "$out" "[link] https://example"    "link node rendered"

# 7. Edges rendered with resolved labels and arrows
assert_contains "$out" "## Edges"                  "edges section present"
assert_contains "$out" "→"                         "edges use arrow"
assert_contains "$out" "Planning"                  "edge — fromNode resolved"
assert_contains "$out" "Execution"                 "edge — toNode resolved"
assert_contains "$out" "feeds into"                "edge label included"

# Edge without label must still render (just fromLabel → toLabel)
assert_contains "$out" "Scope the work"            "unlabeled edge — from node resolved"
assert_contains "$out" "Implement each task"       "unlabeled edge — to node resolved"

echo ""
echo "=== read-canvas — --raw flag ==="

# 9. --raw outputs valid JSON that includes layout fields
raw_out=$("$SCRIPT" --raw "$FIXTURE")
raw_rc=$?
assert_exit 0 "$raw_rc" "--raw exit 0"

# Must be valid JSON
if printf '%s\n' "$raw_out" | python3 -c "import sys, json; json.load(sys.stdin)" 2>/dev/null; then
  pass "--raw output is valid JSON"
else
  fail "--raw output is not valid JSON"
fi

for field in '"x"' '"y"' '"width"' '"height"' '"id"'; do
  assert_contains "$raw_out" "$field" "--raw output contains layout field $field"
done

# --raw output must still reference nodes and edges
assert_contains "$raw_out" "nodes"  "--raw contains nodes key"
assert_contains "$raw_out" "edges"  "--raw contains edges key"
assert_contains "$raw_out" "Planning" "--raw contains group label"

# 10. Unknown flag → exit 1
out=$("$SCRIPT" --unknown 2>&1) || rc=$?; rc=${rc:-0}
assert_exit 1 "$rc" "unknown flag"

# 11. --raw with missing file → still exit 2
out=$("$SCRIPT" --raw /nonexistent/path/canvas.canvas 2>&1) || rc=$?; rc=${rc:-0}
assert_exit 2 "$rc" "--raw nonexistent file"

echo ""
echo "=== summary ==="
echo "  pass=$PASS  fail=$FAIL"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
