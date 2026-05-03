#!/usr/bin/env bash
# Wait for Obsidian's CLI to become reachable against the registered vault.
#
# Compound probe per #89 Section G/Decision 6:
#   1. `obsidian version`   — CLI socket is up.
#   2. `obsidian read path=wiki/hot.md` — registered vault is openable and
#      a known file is readable. Stronger than `version` alone — catches the
#      case where Obsidian booted but the vault failed to open.
#
# 1s poll, 60s cap (AC13). Exits 1 on timeout with a clear message; exit 0 on
# first compound success.
#
# Usage:
#   wait-for-obsidian.sh
#
# Env:
#   WAIT_FOR_OBSIDIAN_TIMEOUT — override the 60s cap (seconds).

set -uo pipefail

TIMEOUT="${WAIT_FOR_OBSIDIAN_TIMEOUT:-60}"
DEADLINE=$(( SECONDS + TIMEOUT ))

echo "wait-for-obsidian: probing CLI readiness (timeout=${TIMEOUT}s)..."

while [ "$SECONDS" -lt "$DEADLINE" ]; do
  if obsidian version >/dev/null 2>&1 \
     && obsidian read path=wiki/hot.md >/dev/null 2>&1; then
    echo "wait-for-obsidian: ready after ${SECONDS}s"
    exit 0
  fi
  sleep 1
done

{
  echo "wait-for-obsidian: timeout after ${TIMEOUT}s — Obsidian CLI never became reachable"
  echo "  Last \`obsidian version\` stderr:"
  obsidian version 2>&1 >/dev/null | sed 's/^/    /' || true
  echo "  Last \`obsidian read path=wiki/hot.md\` output:"
  obsidian read path=wiki/hot.md 2>&1 | head -5 | sed 's/^/    /' || true
} >&2

exit 1
