#!/usr/bin/env bash
VAULT="${user_config.vault_path}"
[ -z "$VAULT" ] && [ -d "$(pwd)/wiki" ] && VAULT="$(pwd)"
if [ -z "$VAULT" ]; then
  echo "claude-obsidian: no vault configured — run /wiki init to set up" >&2
  exit 1
fi
echo "$VAULT"
