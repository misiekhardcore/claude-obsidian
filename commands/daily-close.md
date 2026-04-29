---
description: Synthesize today's daily log into a prose summary with optional follow-ups. Idempotent on re-run.
argument-hint: "[YYYY-MM-DD]"
---

Read the `daily-close` skill. Then run the synthesis flow against today's daily file (`<vault_root>/daily/YYYY-MM-DD.md`), or against the date supplied as the argument if present. Reads the day's captures, date-matched inbox notes and wiki pages, plus `wiki/hot.md` and `wiki/index.md` for cross-reference context. Appends or replaces `## Summary` (and optionally `## Follow-ups`) on the daily file.

If no vault is configured, surface: `No vault configured — run /wiki init first.` If the daily file does not exist for the target date, surface: `No daily file for <date> — nothing to close.`
