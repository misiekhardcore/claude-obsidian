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
# ─── Wrapper-only verbs ──────────────────────────────────────────────────────
# These verbs are not part of the upstream CLI; the wrapper synthesizes them
# from the underlying primitives. They exist so callers (notably skills/daily)
# never have to read-modify-overwrite a file at the model layer.
#
#   create-or-append  file=<path> template=<full-file-template> content=<bullet>
#     File missing → write `template` via `obsidian create`, then append
#     `content`. File exists → append `content` only; `template` is ignored.
#     `template` is required (no caller needs empty-template create).
#     Output: `Created and appended: <path>` (file-missing branch) or
#             `Appended to: <path>` (file-exists branch).
#     Exit:   0 success, 1 generic error (e.g. underlying create/append failed).
#
#   frontmatter-set   path=<path> key=<yaml-key> value=<scalar>
#     Surgical mutation of a single YAML key in the frontmatter block of an
#     existing file. Body bytes are preserved verbatim. If `key` is present,
#     its value is replaced; if absent, `key: value` is inserted at the end of
#     the frontmatter block (just before the closing `---`).
#     Multi-line values and quoted strings are out of scope — scalars only.
#     Output: `Set frontmatter: <path>`.
#     Exit:   0 success, 1 generic error (file missing, no frontmatter block,
#             malformed frontmatter — closing `---` not found).
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

# 4a. Wrapper-only verbs (create-or-append, frontmatter-set) — see header.
#     Both call the underlying `obsidian` binary directly with the resolved
#     vault name; the upstream CLI's stdout-based error reporting is parsed
#     here without needing to recurse through this wrapper.

# run_obs <args...> — call upstream `obsidian` with the resolved vault name,
# print stdout verbatim, and return a normalized exit code (0/1/2 — see the
# header's exit-code table). Used only by the wrapper-only verbs below.
run_obs() {
  local tmp first cli_exit
  tmp="$(mktemp)"
  obsidian "vault=$VAULT_NAME" "$@" >"$tmp" 2>&2
  cli_exit=$?
  cat "$tmp"
  first="$(head -n 1 "$tmp" 2>/dev/null || true)"
  rm -f "$tmp"
  if [ "$cli_exit" -ne 0 ]; then return "$cli_exit"; fi
  case "$first" in
    "Vault not found."*) return 2 ;;
    "Error: "*)          return 1 ;;
    *)                   return 0 ;;
  esac
}

# do_create_or_append — see header for the contract.
do_create_or_append() {
  local file="" template="" content=""
  for arg in "$@"; do
    case "$arg" in
      file=*)     file="${arg#file=}" ;;
      template=*) template="${arg#template=}" ;;
      content=*)  content="${arg#content=}" ;;
      *) echo "Error: create-or-append: unknown argument '$arg'" >&2; return 1 ;;
    esac
  done
  if [ -z "$file" ] || [ -z "$template" ] || [ -z "$content" ]; then
    echo "Error: create-or-append requires file=, template=, and content=" >&2
    return 1
  fi

  # File-exists fast path: try `append` directly. The upstream CLI returns
  # `Error: File "<path>" not found.` on a missing file, otherwise
  # `Appended to: <path>`. One call covers the common case (file exists);
  # only the cold-start (file missing) path pays for the extra `create`.
  # We avoid a separate `read` probe so we don't pull a possibly-large body
  # into memory just to learn whether the file exists.
  local append_out append_first append_rc
  append_out="$(mktemp)"
  obsidian "vault=$VAULT_NAME" append "file=$file" "content=$content" \
    >"$append_out" 2>&2
  append_rc=$?
  append_first="$(head -n 1 "$append_out" 2>/dev/null || true)"
  rm -f "$append_out"

  if [ "$append_rc" -eq 0 ]; then
    case "$append_first" in
      "Appended to: "*)
        echo "Appended to: $file"
        return 0
        ;;
      'Error: File "'*)
        # Fall through to create+append.
        ;;
      "Error: "*)
        echo "$append_first"
        return 1
        ;;
      *)
        # Treat any other non-error first line as a successful append.
        echo "Appended to: $file"
        return 0
        ;;
    esac
  fi

  # File-missing branch: create with template, then append the bullet.
  if ! run_obs create "path=$file" "content=$template" >/dev/null; then
    echo "Error: create-or-append: failed to create $file" >&2
    return 1
  fi
  if ! run_obs append "file=$file" "content=$content" >/dev/null; then
    echo "Error: create-or-append: created $file but append failed" >&2
    return 1
  fi
  echo "Created and appended: $file"
  return 0
}

# do_frontmatter_set — see header for the contract.
do_frontmatter_set() {
  local path="" key="" value=""
  for arg in "$@"; do
    case "$arg" in
      path=*)  path="${arg#path=}" ;;
      key=*)   key="${arg#key=}" ;;
      value=*) value="${arg#value=}" ;;
      *) echo "Error: frontmatter-set: unknown argument '$arg'" >&2; return 1 ;;
    esac
  done
  if [ -z "$path" ] || [ -z "$key" ] || [ -z "$value" ]; then
    echo "Error: frontmatter-set requires path=, key=, and value=" >&2
    return 1
  fi

  # Read the file. Surface CLI errors (missing file → exit 1).
  local current read_rc
  current="$(run_obs read "path=$path")"
  read_rc=$?
  if [ "$read_rc" -ne 0 ]; then
    return "$read_rc"
  fi

  # Surgical YAML key mutation in awk — body bytes are passed through verbatim.
  # Frontmatter delimiters: opening `---` must be the first line; closing `---`
  # is the next line that is exactly `---`. Multi-line values and quoted
  # strings are out of scope (per /define). Diagnostic codes — not user text —
  # are emitted on awk's stdout when the input is malformed; the shell
  # translates them into user-facing messages and discards the partial output.
  local updated awk_rc
  updated="$(printf '%s' "$current" | awk -v key="$key" -v value="$value" '
    BEGIN { state = "pre"; replaced = 0 }
    NR == 1 {
      if ($0 == "---") { state = "fm"; print; next }
      state = "err_no_opening"; exit 2
    }
    state == "fm" {
      if ($0 == "---") {
        if (!replaced) { print key ": " value }
        state = "body"; print; next
      }
      # Match `key:` at the start of the line; later occurrences are ignored.
      if (!replaced && index($0, key ":") == 1) {
        print key ": " value
        replaced = 1
        next
      }
      print; next
    }
    state == "body" { print; next }
    END {
      if (state == "pre" || state == "err_no_opening") print "FM_ERR_NO_OPENING"
      else if (state == "fm") print "FM_ERR_NO_CLOSING"
    }
  ')"
  awk_rc=$?

  case "$updated" in
    *FM_ERR_NO_OPENING*)
      echo "Error: frontmatter-set: $path has no frontmatter block" >&2
      return 1
      ;;
    *FM_ERR_NO_CLOSING*)
      echo "Error: frontmatter-set: $path has malformed frontmatter (no closing ---)" >&2
      return 1
      ;;
  esac
  if [ "$awk_rc" -ne 0 ]; then
    echo "Error: frontmatter-set: awk failed parsing $path" >&2
    return 1
  fi

  # Write back via `obsidian create overwrite=true`. This wrapper-internal
  # call does not pass through the rewrite hook (the hook only fires on the
  # model's Bash tool), so the daily/*.md antipattern guard does not trigger.
  if ! run_obs create "path=$path" overwrite=true "content=$updated" >/dev/null; then
    echo "Error: frontmatter-set: write failed for $path" >&2
    return 1
  fi
  echo "Set frontmatter: $path"
  return 0
}

case "${1:-}" in
  create-or-append) shift; do_create_or_append "$@"; exit $? ;;
  frontmatter-set)  shift; do_frontmatter_set "$@";  exit $? ;;
esac

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
