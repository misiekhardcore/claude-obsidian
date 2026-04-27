# Capture Pipeline

Stable contract for all capture surfaces: `/note`, `/daily`, `/braindump` (sub-issue D), and rich inputs (sub-issue E).
Section headings are **stable anchors** — do not reorder. Future splits patch individual sections in place.

---

## 1. Vault path resolution

Resolve `<vault_root>` by delegating to `scripts/resolve-vault.sh`, which is the canonical implementation used by `wiki`.

Resolution order (matches the script exactly):

1. Legacy explicit path passed as `$1` to `scripts/resolve-vault.sh`, if provided.
2. CWD if it contains a `wiki/` subdirectory.
3. Project setting `claude-obsidian.vault_path` (via `~/.claude/settings.local.json`, then `~/.claude/settings.json`).

```bash
VAULT=$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/resolve-vault.sh") || {
  echo "No vault configured — run /wiki init first."
  exit 1
}
```

If no vault is configured, the script exits 1 and prints to stderr. Surface that to the user as:

```
No vault configured — run /wiki init first.
```

Do not continue.

---

## 2. Frontmatter schema (note + daily)

Both capture shapes use a flat YAML header per `${CLAUDE_PLUGIN_ROOT}/_shared/frontmatter.md`. Neither shape uses the full wiki universal fields (no `confidence`, `evidence`, `related`, `sources` — those belong on polished wiki pages).

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

- `type: note` — additive to the schema in `_shared/frontmatter.md`; no schema change required.
- `topic` — optional free-text grouping. Empty by default.
- `tags` — optional. Empty by default.
- `source_project` — basename of CWD at capture time; used by LIST `--project=…`.
- `status` — `pending` | `deferred`. New captures default to `pending`.

### Daily shape (`type: daily`)

```yaml
---
type: daily
date: YYYY-MM-DD
created: YYYY-MM-DD
updated: YYYY-MM-DD
---
```

- `type: daily` — additive to the schema in `_shared/frontmatter.md`; no schema change required.
- `date` — calendar date this file covers; equals `created`.
- No `title`, `topic`, `tags`, `source_project`, or `status` — daily files are chronological logs, not knowledge objects.

---

## 3. Slug rule (title-driven)

Slugs are computed by the `slug.sh` script — do not slugify inline:

```bash
slug=$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/slug.sh" "$title" "$body")
```

See `scripts/slug.sh` header for the full contract. Exit 1 means both inputs slugify to empty; surface that as an error rather than inventing a name.

The script outputs a lowercase, hyphenated slug (max 40 chars, truncated at the last `-`). This is the canonical slug rule; callers must not duplicate the logic.

Note files use slug in the filename: `<vault_root>/notes/YYYY-MM-DD-<slug>.md`. Daily files do not use a slug — their filename is the date: `<vault_root>/daily/YYYY-MM-DD.md`.

---

## 4. MATCH/NEW heuristic (incl. prompt template)

Used by `/note` CAPTURE only. `/daily` is append-only (no MATCH/NEW — see §7).

### Enumeration

List `<vault_root>/notes/*.md` and read **frontmatter only** for each (title, topic, tags). Skip bodies. Skip `notes/index.md` and any file with `status: deferred`. Cap at the **20 most recent by `updated:`**. Use `mcp__obsidian-vault__obsidian_batch_get_file_contents` when the MCP server is available.

### Decision prompt

```
Existing notes (frontmatter only):
{{for each candidate, render: filename, title, topic, tags}}

New note text:
"""
{{verbatim user text}}
"""

Decide:
- MATCH: <filename> | <one sentence why> — only if a single candidate clearly
  extends or near-duplicates the new content. Required signals (ALL must hold):
    1. (title alignment) OR (topic alignment) — same subject, not just same domain.
    2. (tag overlap ≥ 1) OR (tags empty on both, AND title/topic alignment is strong).
    3. The new content is a logical extension of the existing scope (continuation,
       counter-example, follow-up question on the same thing) — not a new thread.
- NEW — anything ambiguous, weak, cross-cutting, contradictory, or where two
  candidates plausibly fit. The bar is high; default to NEW under doubt.
```

Output exactly one of `MATCH: <filename> | <reason>` or `NEW`. Use `MATCH` only when one candidate stands out clearly; if two plausibly fit, output `NEW`.

### MATCH path

Append to the existing file:

```
<existing body>

---

<new verbatim text>
```

If the new content broadens the note's scope, rewrite `title:` to cover the union. Bump `updated:` to today. `topic:` and `tags:` may be widened; never narrowed. Filename is **never renamed**.

### NEW path

1. Derive a one-line title (≤80 chars), stripping filler ("we need to", "can we check", "I think we should"). If the verbatim text is short, substantive, and one-line, use it directly.
2. Compute slug per §3.
3. Path: `<vault_root>/notes/YYYY-MM-DD-<slug>.md`. If it exists for today, append `-2`, `-3`, …
4. Frontmatter from §2 note shape; body is the verbatim text.

---

## 5. Attachment handling (placeholder for sub-issue E)

Reserved for #64 — image input across capture skills.

---

## 6. Index patching (notes/index.md)

Patch in place after every CAPTURE — never rewrite from scratch.

**NEW:** prepend a row under `## Pending`:

```
- [ ] YYYY-MM-DD [<source_project>] <title>
```

**MATCH:** find the row by the **pre-rewrite title** (the title the file had before this operation). Bump its date to today; if the title was rewritten, replace the title text. Never add a duplicate row.

Row format: `- [ ] YYYY-MM-DD [source_project] title` (pending) or `- [~] YYYY-MM-DD [source_project] title` (deferred).

`notes/index.md` canonical template lives at `_seed/notes/index.md`. Two static sections: `## Pending` and `## Deferred`. Updated on every CAPTURE and PROCESS action. Mirror the patch-in-place pattern used by `/save` and `/ingest`.

---

## 7. Daily page append shape

File path: `<vault_root>/daily/YYYY-MM-DD.md`

### File creation (first call for the day)

If `<vault_root>/daily/` does not exist, create it silently (never abort). Then create the file with frontmatter from §2 daily shape plus an empty `## Captures` section:

```markdown
---
type: daily
date: YYYY-MM-DD
created: YYYY-MM-DD
updated: YYYY-MM-DD
---

## Captures

```

### Append rule

Append one bullet under `## Captures`:

```
- HH:MM <verbatim text>
```

`HH:MM` is the **local-time** hour:minute at append (24-hour clock, zero-padded). No rounding, no counter on duplicate timestamps.

If `## Captures` heading is missing from an existing file, append it at EOF before the bullet (idempotent — never duplicate the heading).

### Idempotency

- One new bullet per invocation, no deduplication.
- Multiple calls in the same minute land bullets with the same `HH:MM` prefix in file order — no collision handling.
- `updated:` in frontmatter is bumped to today on every append.

### No MATCH/NEW

Every `/daily` call adds a new bullet. No candidate enumeration, no MATCH/NEW decision, no index patching. Daily files are chronological logs, not knowledge objects.
