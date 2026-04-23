#!/usr/bin/env bash
# Resolve the vault path in priority order:
#   1. $1 argument (legacy; no longer passed by hooks as of #36)
#   2. $(pwd) if it contains a wiki/ subdirectory
#   3. ~/.claude/settings.local.json  (pluginConfigs[*claude-obsidian*].options.vault_path)
#   4. ~/.claude/settings.json        (same key, userSettings scope written by /plugin manage)
VAULT="${1:-}"
[ -z "$VAULT" ] && [ -d "$(pwd)/wiki" ] && VAULT="$(pwd)"

read_vault_from_settings() {
  local file="$1"
  [ -f "$file" ] || return 0
  if command -v jq >/dev/null 2>&1; then
    jq -r '(.pluginConfigs // {}) | to_entries[] | select(.key | contains("claude-obsidian")) | .value.options.vault_path // empty' "$file" 2>/dev/null | head -1
  elif command -v python3 >/dev/null 2>&1; then
    SETTINGS_FILE="$file" python3 -c '
import json, os
try:
    with open(os.environ["SETTINGS_FILE"]) as f:
        d = json.load(f)
    for k, v in d.get("pluginConfigs", {}).items():
        if "claude-obsidian" in k:
            print(v.get("options", {}).get("vault_path", ""))
            break
except Exception:
    pass
' 2>/dev/null
  fi
}

for settings_file in "$HOME/.claude/settings.local.json" "$HOME/.claude/settings.json"; do
  [ -n "$VAULT" ] && break
  VAULT=$(read_vault_from_settings "$settings_file")
done

if [ -z "$VAULT" ]; then
  echo "claude-obsidian: no vault configured — run /wiki init to set up" >&2
  exit 1
fi
echo "$VAULT"
