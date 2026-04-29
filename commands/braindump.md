---
description: Split long-form text into atomic notes and file each via the capture pipeline. Triage later with /note process.
argument-hint: "<text or file path>"
---

Read the `braindump` skill. Then run the SPLIT-then-CAPTURE flow with the argument(s) — either inline text, a vault-relative or absolute file path, or a supported image path. Each atomic chunk is filed through the standard `/note` CAPTURE pipeline (MATCH/NEW per chunk).

If the argument is empty, surface: `Usage: /braindump <text or file path>`. If no vault is configured, surface: `No vault configured — run /wiki init first.`
