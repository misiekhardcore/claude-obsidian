# Capture Pipeline

Stable contract for capture surfaces: `/note`, `/daily`, `/braindump`. Section headings are **stable anchors** — do not reorder.

## 1. Vault path resolution

Resolve `<vault_root>` via `scripts/resolve-vault.sh` (canonical implementation).

Resolution order:
1. Legacy explicit path passed as `$1`
2. CWD if it contains `wiki/`
3. `claude-obsidian.vault_path` setting

```bash
VAULT=$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/resolve-vault.sh") || {
  echo "No vault configured — run /wiki init first."
  exit 1
}
```

## 2. Frontmatter schema (note + daily)

Both use flat YAML per `${CLAUDE_PLUGIN_ROOT}/_shared/frontmatter.md`. Captures omit universal fields (`confidence`, `evidence`, `related`, `sources` — reserved for polished pages).

### Note shape (`type: note`)

```yaml
---
type: note
title: "<one-line summary, ≤80 chars>"
topic: ""
tags: []
created: YYYY-MM-DD
updated: YYYY-MM-DD
source_project: "<cwd basename at capture time>"
status: pending
---
```

- `topic` — optional free-text grouping
- `tags` — optional
- `source_project` — CWD basename; used by LIST `--project=…`
- `status` — `pending` | `deferred`

### Daily shape (`type: daily`)

```yaml
---
type: daily
date: YYYY-MM-DD
created: YYYY-MM-DD
updated: YYYY-MM-DD
---
```

No `title`, `topic`, `tags`, `source_project`, or `status` — daily files are append-only chronological logs.

## 3. Slug rule (title-driven)

Use `scripts/slug.sh` (canonical implementation):

```bash
slug=$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/slug.sh" "$title" "$body")
```

Output: lowercase, hyphenated, max 40 chars. Exit 1 if both inputs are empty.

- Note files: `<vault_root>/notes/YYYY-MM-DD-<slug>.md`
- Daily files: `<vault_root>/daily/YYYY-MM-DD.md` (no slug)

## 4. MATCH/NEW heuristic

Used by `/note` only. `/daily` is append-only (no MATCH/NEW).

### Enumeration

List `<vault_root>/notes/*.md` (frontmatter only; skip bodies, `notes/index.md`, `status: deferred`). Cap at 20 most recent by `updated:`. Use `obsidian properties path=notes/<file>` per candidate.

### Decision

One of: `MATCH: <filename> | <reason>` or `NEW`.

MATCH only if **all three hold:**
1. Title or topic alignment (same subject, not just domain)
2. Tag overlap ≥1, OR tags empty on both with strong title/topic alignment
3. New content is logical extension (continuation, counter-example, follow-up on same topic)

Default to NEW on ambiguity; high bar for MATCH.

### MATCH path

Append to existing file with `---` separator. If new content broadens scope, rewrite `title:` to cover union. Bump `updated:`. Filename never changes.

### NEW path

1. Derive one-line title (≤80 chars), stripped of filler
2. Compute slug per §3
3. Path: `<vault_root>/notes/YYYY-MM-DD-<slug>.md`; collisions: `-2`, `-3`, …
4. Frontmatter per §2; body is verbatim text

## 5. Attachment handling

See `_shared/image-capture.md` for validation, vision-LLM, move mechanics, embed syntax, and error handling.

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
