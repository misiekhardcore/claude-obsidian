#!/usr/bin/env bash
# Resolve a plugin config value in priority order:
#   1. ~/.claude/settings.local.json  (pluginConfigs[*claude-obsidian*].options.<key>)
#   2. ~/.claude/settings.json        (same key, userSettings scope)
#   3. $2 default (if provided)
# Usage: resolve-config.sh <key> [default]
KEY="${1:-}"
DEFAULT="${2:-}"

if [ -z "$KEY" ]; then
  echo "resolve-config.sh: key argument required" >&2
  exit 1
fi

read_config_from_settings() {
  local file="$1"
  [ -f "$file" ] || return 0
  if command -v jq >/dev/null 2>&1; then
    jq -r --arg key "$KEY" '(.pluginConfigs // {}) | to_entries[] | select(.key | contains("claude-obsidian")) | .value.options[$key] // empty' "$file" 2>/dev/null | head -1
  elif command -v python3 >/dev/null 2>&1; then
    SETTINGS_FILE="$file" CONFIG_KEY="$KEY" python3 -c '
import json, os
try:
    with open(os.environ["SETTINGS_FILE"]) as f:
        d = json.load(f)
    key = os.environ["CONFIG_KEY"]
    for k, v in d.get("pluginConfigs", {}).items():
        if "claude-obsidian" in k:
            val = v.get("options", {}).get(key, "")
            if val:
                print(val)
            break
except Exception:
    pass
' 2>/dev/null
  fi
}

VALUE=""
for settings_file in "$HOME/.claude/settings.local.json" "$HOME/.claude/settings.json"; do
  [ -n "$VALUE" ] && break
  VALUE=$(read_config_from_settings "$settings_file")
done

if [ -z "$VALUE" ]; then
  echo "${DEFAULT}"
else
  echo "$VALUE"
fi
