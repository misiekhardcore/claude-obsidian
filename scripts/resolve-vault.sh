#!/usr/bin/env bash
VAULT="${1:-}"
[ -z "$VAULT" ] && [ -d "$(pwd)/wiki" ] && VAULT="$(pwd)"
if [ -z "$VAULT" ] && [ -f "$HOME/.claude/settings.local.json" ]; then
  if command -v jq >/dev/null 2>&1; then
    VAULT=$(jq -r '(.pluginConfigs // {}) | to_entries[] | select(.key | contains("claude-obsidian")) | .value.options.vault_path // empty' "$HOME/.claude/settings.local.json" 2>/dev/null | head -1)
  elif command -v python3 >/dev/null 2>&1; then
    VAULT=$(python3 -c "
import json, sys
try:
    with open('$HOME/.claude/settings.local.json') as f:
        d = json.load(f)
    for k, v in d.get('pluginConfigs', {}).items():
        if 'claude-obsidian' in k:
            print(v.get('options', {}).get('vault_path', ''))
            break
except Exception:
    pass
" 2>/dev/null)
  fi
fi
if [ -z "$VAULT" ]; then
  echo "claude-obsidian: no vault configured — run /wiki init to set up" >&2
  exit 1
fi
echo "$VAULT"
