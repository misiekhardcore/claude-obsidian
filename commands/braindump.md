---
description: Split long-form text into atomic notes and file each via the capture pipeline. Dispatches parallel agents when chunks are independent; runs sequentially when order matters.
argument-hint: <text or file path>
---
Run `braindump` skill with argument: inline text, vault-relative/absolute file path, or image. SPLIT-then-CAPTURE each chunk through `/note` pipeline (MATCH/NEW). Dispatch parallel agents when independent, sequential when order matters. Triage with `/note process`.

Usage: `/braindump <text or file path>`. If no vault: "No vault configured — run /wiki init first."
