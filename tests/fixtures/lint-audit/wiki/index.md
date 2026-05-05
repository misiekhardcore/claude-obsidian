---
type: meta
title: "Index"
created: 2026-05-05
updated: 2026-05-05
tags:
  - meta
  - index
status: evergreen
confidence: EXTRACTED
evidence: []
related: []
---

# Index

Lint-audit fixture vault index. Contains planted violations for checks #8 and #15.

## Concepts

- [[concept-a]] — page with empty section (check #7) and WidgetFoo mention (check #4)
- [[concept-b]] — page with WidgetFoo mention (check #4) and unlinked entity-b (check #5)
- [[older-claim]] — page with stale claim (check #3)
- [[source-misplaced]] — intentionally misplaced source under Concepts (check #15)

## Sources

- [[newer-source]] — contradicts older-claim (check #3 evidence)

## Entities

- [[entity-b]] — entity referenced without wikilink in concept-b (check #5)
- [[old-renamed-page]] — stale index entry; this page was renamed to concept-a (check #8)
