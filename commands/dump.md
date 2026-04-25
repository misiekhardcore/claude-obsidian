---
description: Dump a verbatim thought into the notes inbox. Alias for /note <text>.
argument-hint: "<verbatim text>"
---

Read the `notes` skill, then run the CAPTURE operation with the argument as the verbatim text. Same behaviour as `/note <text>` — silent auto-match append on overlap, silent file creation on no match. No prompts.

If the argument is empty, surface: `Usage: /dump <verbatim text>`. If no vault is configured, surface: `No vault configured — run /wiki init first.`
