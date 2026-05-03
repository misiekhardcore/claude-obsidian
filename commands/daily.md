---
description: Append a timestamped bullet to today's daily log in the vault.
argument-hint: "<verbatim text>"
---

Read the `daily` skill. Then run the CAPTURE operation with the argument as the verbatim text. Append one bullet `- HH:MM <text>` under `## Captures` in `<vault_root>/daily/YYYY-MM-DD.md`. Create the directory and file if missing.

**Vault I/O for the daily file is restricted (issue #98):** use exactly the two wrapper-only verbs `obsidian create-or-append` (atomic append, creates the file with the documented frontmatter+heading template if missing) and `obsidian frontmatter-set` (surgical `updated:` bump). Do **not** use `Edit`, `Write`, `obsidian create overwrite=true`, or any read-modify-overwrite sequence against `daily/*.md` — the rewrite hook rejects the `overwrite=true` shape, and the read-modify-write antipattern is the root cause of the bullet-loss bug.

If the argument is empty, surface: `Usage: /daily <verbatim text>`. If no vault is configured, surface: `No vault configured — run /wiki init first.`
