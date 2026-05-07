---
description: End-of-day synthesis. Reads captures and context, synthesizes a prose summary with optional follow-ups. Idempotent on re-run.
argument-hint: "[YYYY-MM-DD]"
---
Run `daily-close` skill against today's daily file or supplied date. Reads captures, dated notes/wiki pages, hot.md, index.md. Appends/replaces `## Summary` and optional `## Follow-ups`.

Dispatches sub-agents for large page reads. Idempotent: re-run to re-synthesize.

If no vault: "No vault configured — run /wiki init first." If no daily file: "No daily file for <date> — nothing to close."
