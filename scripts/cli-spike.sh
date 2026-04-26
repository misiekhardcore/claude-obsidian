#!/usr/bin/env bash
# CLI spike: empirically probe the Obsidian CLI surface used by claude-obsidian.
#
# Captures stdout, stderr, and exit code for every in-scope verb. Output goes to
# tests/spike-results/<group>-<verb>-<case>.{out,err,exit}.
#
# The spike script always exits 0 — exit codes are the data, not the test.
# Re-run after every Obsidian CLI minor-version bump and update the wrapper
# header (scripts/obsidian-cli.sh) and smoke header (tests/cli-smoke.sh) if
# the contract has changed.
#
# Vault: defaults to the currently active Obsidian vault. Override with
#   SPIKE_VAULT_NAME=<name> bash scripts/cli-spike.sh
#
# All writes happen under a `_spike-scratch/` subdirectory in the target vault
# and are cleaned up at the end. Re-runs wipe tests/spike-results/ first.
#
# Note: The spike captures CLI BEHAVIOR (exit codes, format shapes, error
# patterns). Fixture-specific assertions (correct orphan list, correct
# backlinks, etc.) are the smoke test's job, not the spike's.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
RESULTS_DIR="$PLUGIN_ROOT/tests/spike-results"

# Resolve target vault: SPIKE_VAULT_NAME env > first vault in `obsidian vaults`.
VAULT_NAME="${SPIKE_VAULT_NAME:-}"
if [ -z "$VAULT_NAME" ]; then
  VAULT_NAME=$(obsidian vaults verbose 2>/dev/null | awk -F'\t' 'NR==1{print $1}')
fi

if [ -z "$VAULT_NAME" ]; then
  echo "spike: could not resolve a target vault (no SPIKE_VAULT_NAME and no vaults from obsidian vaults)" >&2
  exit 0
fi

SCRATCH="_spike-scratch"

mkdir -p "$RESULTS_DIR"

# capture <group> <verb> <case> -- <obsidian args...>
capture() {
  local group="$1" verb="$2" case_id="$3"
  shift 3
  [ "$1" = "--" ] && shift
  local base="$RESULTS_DIR/${group}-${verb}-${case_id}"
  obsidian "$@" >"$base.out" 2>"$base.err"
  echo "$?" >"$base.exit"
  printf '  %-30s %s\n' "${verb}-${case_id}" "exit=$(cat "$base.exit")"
}

# Group: meta — version probe + vault listing (no fixture dependency)
spike_meta() {
  echo "[meta]"
  capture meta version ok           -- version
  capture meta vaults  list         -- vaults verbose
  capture meta vault   info         -- vault=$VAULT_NAME vault
  capture meta vault   notfound     -- vault=__definitely_not_a_vault__ vault
  capture meta unknown verb         -- vault=$VAULT_NAME doesnotexistverb
  capture meta vault   bypath       -- vault=/tmp vault
}

# Group: notes — properties, read (used by skills/notes)
spike_notes() {
  echo "[notes]"
  capture notes read missing        -- vault=$VAULT_NAME read path=$SCRATCH/missing.md
  capture notes read malformed      -- vault=$VAULT_NAME read
}

# Group: lint — backlinks, orphans, deadends, unresolved, search, tags, tasks
spike_lint() {
  echo "[lint]"
  capture lint backlinks default    -- vault=$VAULT_NAME backlinks path=wiki/index.md
  capture lint backlinks json       -- vault=$VAULT_NAME backlinks path=wiki/index.md format=json
  capture lint orphans  default     -- vault=$VAULT_NAME orphans
  capture lint orphans  json        -- vault=$VAULT_NAME orphans format=json
  capture lint deadends default     -- vault=$VAULT_NAME deadends
  capture lint deadends json        -- vault=$VAULT_NAME deadends format=json
  capture lint unresolved default   -- vault=$VAULT_NAME unresolved
  capture lint unresolved json      -- vault=$VAULT_NAME unresolved format=json
  capture lint tags    default      -- vault=$VAULT_NAME tags
  capture lint tasks   default      -- vault=$VAULT_NAME tasks
}

# Group: ingest — create, append, prepend, read (used by skills/ingest)
spike_ingest() {
  echo "[ingest]"
  capture ingest create simple      -- vault=$VAULT_NAME create path=$SCRATCH/created.md content="created by spike" overwrite
  capture ingest create multiline   -- vault=$VAULT_NAME create path=$SCRATCH/multiline.md content="line one\nline two\nline three" overwrite
  capture ingest read multiline     -- vault=$VAULT_NAME read path=$SCRATCH/multiline.md
  capture ingest append simple      -- vault=$VAULT_NAME append path=$SCRATCH/created.md content="appended line"
  capture ingest prepend simple     -- vault=$VAULT_NAME prepend path=$SCRATCH/created.md content="prepended line"
  capture ingest read final         -- vault=$VAULT_NAME read path=$SCRATCH/created.md
  capture ingest create no_args     -- vault=$VAULT_NAME create
}

# Group: canvas — read, create (used by skills/canvas)
spike_canvas() {
  echo "[canvas]"
  capture canvas create ok          -- vault=$VAULT_NAME create path=$SCRATCH/test.canvas content='{"nodes":[],"edges":[]}' overwrite
  capture canvas read ok            -- vault=$VAULT_NAME read path=$SCRATCH/test.canvas
}

# Group: bases — bases, base:create, base:query (used by skills/obsidian-bases)
spike_bases() {
  echo "[bases]"
  capture bases list                -- vault=$VAULT_NAME bases
}

# Group: query+save — pure read + read-mutate-write cycle (used by skills/{query,save})
spike_query_save() {
  echo "[query/save]"
  capture qs read scratch_create    -- vault=$VAULT_NAME create path=$SCRATCH/index-rmw.md content="# index\n\n- existing entry\n" overwrite
  capture qs read before            -- vault=$VAULT_NAME read path=$SCRATCH/index-rmw.md
  capture qs prepend  index         -- vault=$VAULT_NAME prepend path=$SCRATCH/index-rmw.md content="- prepended entry\n"
  capture qs read after             -- vault=$VAULT_NAME read path=$SCRATCH/index-rmw.md
}

# Group: full read-mutate-write cycle — proves the round-trip
spike_read_mutate_write() {
  echo "[read-mutate-write]"
  local before after diff_file
  before="$RESULTS_DIR/rmw-before.out"
  after="$RESULTS_DIR/rmw-after.out"
  diff_file="$RESULTS_DIR/rmw-mutate-diff.out"

  obsidian vault=$VAULT_NAME create path=$SCRATCH/rmw.md content="# rmw\n\noriginal line\n" overwrite >/dev/null 2>&1
  obsidian vault=$VAULT_NAME read path=$SCRATCH/rmw.md >"$before" 2>/dev/null
  capture rmw mutate prepend         -- vault=$VAULT_NAME prepend path=$SCRATCH/rmw.md content="prepended line\n"
  obsidian vault=$VAULT_NAME read path=$SCRATCH/rmw.md >"$after"  2>/dev/null
  diff "$before" "$after" >"$diff_file" 2>&1 || true
}

# Group: command — escape-hatch via Obsidian command IDs
spike_command() {
  echo "[command]"
  capture cmd commands list         -- vault=$VAULT_NAME commands filter=app:
  capture cmd command  badid        -- vault=$VAULT_NAME command id=__definitely_not_a_command__
}

# Group: closed — capture behavior when Obsidian is not running
spike_closed() {
  echo "[closed]"
  if pgrep -f "obsidian.*Obsidian|/[Oo]bsidian$|obsidian-app" >/dev/null 2>&1 || pgrep -x obsidian >/dev/null 2>&1; then
    echo "obsidian-running, skipping closed-state probe (manual: quit Obsidian, re-run with SPIKE_INCLUDE_CLOSED=1)" \
      >"$RESULTS_DIR/closed-skipped.out"
  else
    capture closed version off        -- version
    capture closed read    off        -- vault=$VAULT_NAME read path=wiki/hot.md
  fi
}

cleanup_scratch() {
  echo
  echo "[cleanup]"
  # Best-effort scratch cleanup. Resolve the vault path so we can remove the
  # whole scratch tree directly (the CLI has no batch-delete verb).
  local vault_path
  vault_path="$("$SCRIPT_DIR/resolve-vault.sh" 2>/dev/null || true)"
  if [ -n "$vault_path" ] && [ -d "$vault_path/$SCRATCH" ]; then
    rm -rf "$vault_path/$SCRATCH"
    rm -f "$vault_path/Untitled.md"
    echo "  removed $vault_path/$SCRATCH/ and stray Untitled.md"
  else
    echo "  no scratch directory to clean"
  fi
}

main() {
  echo "obsidian-cli spike — vault: $VAULT_NAME — scratch: $SCRATCH/"
  echo "results: $RESULTS_DIR"
  echo

  rm -rf "$RESULTS_DIR"
  mkdir -p "$RESULTS_DIR"

  echo "vault: $VAULT_NAME" >"$RESULTS_DIR/_meta.txt"
  echo "scratch: $SCRATCH" >>"$RESULTS_DIR/_meta.txt"
  echo "obsidian-version: $(obsidian version 2>/dev/null)" >>"$RESULTS_DIR/_meta.txt"
  echo "ran-at: $(date --iso-8601=seconds)" >>"$RESULTS_DIR/_meta.txt"

  spike_meta
  spike_notes
  spike_lint
  spike_ingest
  spike_canvas
  spike_bases
  spike_query_save
  spike_read_mutate_write
  spike_command
  spike_closed
  cleanup_scratch

  echo
  echo "spike complete — review $RESULTS_DIR/"
}

main "$@"
exit 0
