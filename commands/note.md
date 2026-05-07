---
description: Capture a quick inbox note (or list/process the inbox) without breaking flow.
argument-hint: "[list|process|<verbatim text>]"
---
Run `notes` skill based on argument:
- `/note <text>` — CAPTURE (verbatim, no rewrite/summarise/tag)
- `/note list [--project=<basename>]` — LIST pending + deferred notes (honour project filter)
- `/note process [--include-deferred]` — PROCESS pending notes one at a time (route to /save, defer, or delete)

Usage: `/note <text> | /note list | /note process`. If no vault: "No vault configured — run /wiki init first."
