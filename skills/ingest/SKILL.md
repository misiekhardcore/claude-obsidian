---
name: ingest
description: Ingest sources into wiki. Extracts entities/concepts, creates/updates pages, cross-references. Supports files and URLs.
when_to_use: Use when the user provides a URL or file path to read and integrate into the wiki as structured pages.
allowed-tools: Agent Bash Read WebFetch
---
# ingest

Read source. Write wiki. Cross-reference everything. Single source typically touches 8-15 pages. Use obsidian-markdown skill for syntax.

## Delta Tracking
Check `.raw/.manifest.json` before ingesting any file to avoid re-processing.
- **Pattern**: `md5sum [file] | cut -d' ' -f1` → check hash in manifest → skip if match.
- **After**: Record `{hash, ingested_at, pages_created, pages_updated}`.
- **Bypass**: Skip if user says "force ingest" or "re-ingest".

## Vault I/O
[Instructions on how to interact with the vault](${CLAUDE_PLUGIN_ROOT}/_shared/vault-ops.md).


## Ingestion Flows

### URL Ingestion
1. **Fetch**: WebFetch → (Optional) `defuddle [url]` to strip clutter.
2. **Slug**: Derive via `bash ${CLAUDE_PLUGIN_ROOT}/scripts/slug.sh "url-last-segment"`.
3. **Archive**: Save to `.raw/articles/slug-YYYY-MM-DD.md` with frontmatter (`source_url`, `fetched`).
4. **Process**: Proceed to Single Source Ingest.

### Image/Vision Ingestion
1. **Read**: Process image natively.
2. **Describe**: Extract text (OCR), identify concepts, entities, diagrams.
3. **Slug**: Derive via `slug.sh` from filename.
4. **Archive**: Save description to `.raw/images/slug-YYYY-MM-DD.md` with frontmatter (`source_type: image`, `original_file`, `fetched`).
5. **Attachment**: Copy image to `_attachments/images/slug.ext`.
6. **Process**: Proceed to Single Source Ingest.

### Single Source Ingest
1. **Read**: Full source from `.raw/`.
2. **Collaborate**: Discuss emphasis, granularity, and context with user. **Wait for response** unless "auto-ingest" or "just ingest it" is specified.
3. **Execute**: Dispatch `agents/ingest.md` with `source_path`, `vault_path`, and `emphasis`.
4. **Reconcile**:
   - Update `wiki/index.md` for all `Created` pages.
   - Update `wiki/hot.md`.
   - Append to `wiki/log.md` (per `_shared/vault-ops.md`).

### Batch Ingest
1. **Fan-out**: Dispatch one `agents/ingest.md` per source in parallel.
2. **Wait**: Collect all reports.
3. **Cross-reference**: Identify connections across sources.
4. **Aggregate**: Update index, hot cache, and log **once** at the end.

## Token & Quality Discipline
- **Token**: Read `hot.md` first → `index.md` → 3-5 existing pages max. Use PATCH for edits.
- **Contradictions**: If new info conflicts, use `[!contradiction]` callout (defined in `.obsidian/snippets/vault-colors.css`).
  - **Leaf**: Add contradiction callout referencing the new source.
  - **Source**: Add contradiction callout referencing the existing page.
  - **Rule**: Do not silently overwrite. Flag and let user decide.

## Scope
- **Do Not**: Modify `.raw/`, create duplicates, skip log/hot-cache updates.
