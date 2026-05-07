---
description: Save the current conversation or a specific insight into the wiki vault as a structured note.
argument-hint: "[name|session|concept [name]|decision [name]]"
---
Run `save` skill. Usage:
- `/save` — analyze conversation and save most valuable content
- `/save [name]` — save with specific title (skip naming)
- `/save session` — complete session summary
- `/save concept [name]` — explicit concept page
- `/save decision [name]` — explicit decision record

Check for existing page; offer to update instead of duplicate.

If no vault: "No wiki vault found. Run /wiki first to set one up."
