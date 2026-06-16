# Index Patching & Daily Append

## 6. Index patching (notes/index.md)

Patch in place (never rewrite).

**NEW:** prepend row under `## Pending`:

```text
- [ ] YYYY-MM-DD [<source_project>] <title>
```

**MATCH:** find row by pre-rewrite title; bump date if title changed.

Row format: `- [ ] YYYY-MM-DD [source_project] title` (pending) or `- [~]` (deferred).

Template at `_seed/notes/index.md` with two sections: `## Pending` and `## Deferred`.

## 7. Daily page append shape

File: `<vault_root>/daily/YYYY-MM-DD.md`

### Creation (first call for the day)

Create `daily/` if missing. Create file with frontmatter per §2 daily shape + empty `## Captures`.

### Append rule

Append bullet under `## Captures`:

```text
- HH:MM <verbatim text>
```

`HH:MM` is local-time 24-hour clock (zero-padded). Add `## Captures` heading idempotently if missing.

### Idempotency

- One bullet per call, no dedup
- Same-minute calls land in file order (no collision handling)
- Bump `updated:` to today on each append

### No MATCH/NEW

Append-only; daily files are logs, not knowledge objects.
