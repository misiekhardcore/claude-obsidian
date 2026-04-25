---
description: Capture a quick inbox note (or list/process the inbox) without breaking flow.
argument-hint: "[list|process|<verbatim text>]"
---

Read the `notes` skill. Then dispatch based on the argument:

- `/note <text>` — capture mode. Pass the verbatim text to the skill's CAPTURE operation. Do not rewrite, summarise, or tag.
- `/note list [--project=<basename>]` — LIST operation. Show pending + deferred notes; honour the project filter.
- `/note process [--include-deferred]` — PROCESS operation. Walk pending notes one at a time; route each to `/save`, defer, or delete.

If the argument is empty (`/note` alone), show usage:

```
/note <text>           Capture a verbatim note to the inbox
/note list             Show the inbox
/note process          Triage the inbox
```

If no vault is configured, surface: `No vault configured — run /wiki init first.`
