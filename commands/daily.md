---
description: Append a timestamped bullet to today's daily log in the vault.
argument-hint: "<verbatim text>"
---

Read the `daily` skill. Then run the CAPTURE operation with the argument as the verbatim text. Append one bullet `- HH:MM <text>` under `## Captures` in `<vault_root>/daily/YYYY-MM-DD.md`. Create the directory and file if missing.

If the argument is empty, surface: `Usage: /daily <verbatim text>`. If no vault is configured, surface: `No vault configured — run /wiki init first.`
