#!/usr/bin/env bash
# obsidian-cli.sh — wrapper for the Obsidian CLI used by every claude-obsidian skill.
#
# Resolves the vault, derives the vault name (basename), pre-flights
# `obsidian version`, runs the verb, and normalizes the upstream CLI's
# always-zero exit code into something callers can act on. stdout/stderr from
# the underlying CLI are passed through verbatim — the exit code is the only
# normalization on the output channel.
#
# Usage:
#   scripts/obsidian-cli.sh <verb> [arg=value ...]
#
# A PreToolUse Bash hook (hooks/obsidian-cli-rewrite.sh) transparently rewrites
# raw `obsidian <verb> ...` calls into this wrapper. Skills should still invoke
# the wrapper explicitly; the rewrite is a guard rail for raw shell-outs.
#
# ─── Exit codes ──────────────────────────────────────────────────────────────
#   0 — success
#   1 — generic CLI error      (stdout starts with "Error:")
#   2 — vault not found        (stdout literal first line "Vault not found.")
#   3 — pre-flight failed      (binary missing, Obsidian not running, no version)
#   4 — vault resolution failed (resolve-vault.sh exited non-zero)
#
# Callers that want hook-style fail-soft pipe `|| exit 0`.
#
# ─── stdout error patterns the wrapper detects ───────────────────────────────
# Upstream always returns exit 0; the wrapper inspects only the first line of
# stdout to decide between success and the error codes above.
#
#   "Error: File \"<path>\" not found."         → exit 1 (read/append/prepend
#                                                          against missing file)
#   "Error: Command \"<verb>\" not found. ..."  → exit 1 (unknown verb)
#   "Error: Command \"<id>\" not found. ..."    → exit 1 (bad `command id=...`)
#   "Error: No active file. ..."                → exit 1 (verb needs a file)
#   "Vault not found."                          → exit 2 (wrong vault name, or
#                                                         a path was passed)
#   <empty stdout, exit 0>                      → exit 0 (e.g. command id=...)
#   <non-empty stdout, no Error: prefix>        → exit 0 (success)
#
# New error shapes from a future CLI version must be captured by re-running
# scripts/cli-spike.sh and added here.
#
# ─── vault=<name> is name-only ───────────────────────────────────────────────
# The CLI's `vault=` parameter accepts a vault NAME (basename), not a path.
# Passing `vault=/some/path` returns "Vault not found." with exit 0. The
# wrapper always passes the basename of $VAULT so callers never have to think
# about it.
#
# ─── Escape hatches (in increasing risk order) ───────────────────────────────
#   1. `obsidian-cli.sh command id=<command-id>` — runs an Obsidian command by
#      ID (same IDs as the command palette). Discover with
#      `obsidian-cli.sh commands filter=<prefix>`. Freely allowed.
#   2. `obsidian-cli.sh eval code=<js>` — runs arbitrary JS in Obsidian's
#      renderer. Last resort. Every call needs a per-call comment in the
#      calling skill explaining why no structured verb suffices.
#   3. Direct Read/Write/Edit on vault files — reserved for the documented
#      exceptions below. Don't entrench bug workarounds; file the bug.
#
# ─── Documented exceptions (bypasses are intentional) ────────────────────────
#   • .raw/.manifest.json           — bookkeeping for raw inbox; not a wiki page
#   • _attachments/images/**        — binary writes; CLI has no binary verb
#   • cron-time writes when Obsidian is closed — see commands/cron.md
#   • bin/setup-vault.sh, bin/seed-demo.sh — operate before vault registration
#
# ─── Empirical contract ──────────────────────────────────────────────────────
# Every behavior above is verified by tests/cli-smoke.sh and backed by the
# captures in tests/spike-results/. After every Obsidian CLI minor-version
# bump, re-run scripts/cli-spike.sh and update this header if the contract
# changes.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 1. Resolve vault path. Failure is exit 4 — callers that want fail-soft chain `|| exit 0`.
VAULT="$("$SCRIPT_DIR/resolve-vault.sh")" || exit 4
[ -n "$VAULT" ] || exit 4

# 2. Derive vault name (basename) — CLI accepts vault=<name>, not path.
VAULT_NAME="$(basename "$VAULT")"

# 3. Pre-flight: obsidian binary present and Obsidian running.
#    `obsidian version` returns "X.Y.Z (installer A.B.C)" when the desktop app
#    is reachable. Empty output or non-zero exit → bail with exit 3.
if ! command -v obsidian >/dev/null 2>&1; then
  echo "obsidian-cli: obsidian binary not on PATH" >&2
  exit 3
fi
VERSION_OUT="$(obsidian version 2>/dev/null || true)"
if [ -z "$VERSION_OUT" ]; then
  echo "obsidian-cli: 'obsidian version' returned no output (Obsidian not running?)" >&2
  exit 3
fi

# 4. Run the verb. Capture stdout so we can inspect it for error markers.
#    The CLI itself always exits 0, so its real exit is uninformative — we
#    detect errors from stdout per the patterns in this script's header.
TMP_OUT="$(mktemp)"
trap 'rm -f "$TMP_OUT"' EXIT

obsidian "vault=$VAULT_NAME" "$@" >"$TMP_OUT" 2>&2
CLI_EXIT=$?

# 5. Pass stdout through to the caller verbatim.
cat "$TMP_OUT"

# 6. Normalize exit code based on stdout's first line.
FIRST_LINE="$(head -n 1 "$TMP_OUT" 2>/dev/null || true)"

# Honour the CLI's own non-zero exit if it ever emits one.
if [ "$CLI_EXIT" -ne 0 ]; then
  exit "$CLI_EXIT"
fi

case "$FIRST_LINE" in
  "Vault not found."*) exit 2 ;;
  "Error: "*)          exit 1 ;;
  *)                   exit 0 ;;
esac
