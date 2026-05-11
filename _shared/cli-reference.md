# CLI Reference — Exit Codes and Escape Hatches

## Exit-code table

|Code|Meaning|Pattern|
|-|-|-|
|0|Success|Non-error output or empty stdout|
|1|CLI error|`Error: ...`|
|2|Vault not found|`Vault not found.`|
|3|Pre-flight failed|Binary missing or Obsidian not running|
|4|Vault resolution failed|`resolve-vault.sh` exited non-zero|

**Error patterns (exit 1):**
- `Error: File "<path>" not found.` — missing file
- `Error: Command "<verb>" not found.` — unknown verb or bad `command id=`
- `Error: No active file...` — missing `file=` or `path=`

## Escape-hatch policy

1. **`command id=<command-id>`** — run registered Obsidian command. Discover with `commands filter=<prefix>`. Exit 1 if not found.
2. **`eval code=<js>`** — last resort only. Must explain why in comment. Behavior not guaranteed across versions.
3. **Direct `Read`/`Write`/`Edit` on vault paths** — reserved exceptions in §6 only.
