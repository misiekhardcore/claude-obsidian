---
name: defuddle
description: Strip ads, nav, boilerplate from web pages. Saves 40-60% tokens. Use before URL ingestion.
allowed-tools: Read Bash
---
# defuddle

Extract meaningful content from web pages: drop ads, nav, cookie banners, footers, related articles. Optional but recommended (saves 40-60% tokens, cleaner wiki pages).

## Install

```bash
npm install -g defuddle-cli
```

Verify: `defuddle --version`

## Usage

### Clean a URL directly

```bash
defuddle https://example.com/article
```

Outputs clean markdown to stdout.

### Save to .raw/

```bash
defuddle https://example.com/article > .raw/articles/article-slug-$(date +%Y-%m-%d).md
```

### Add frontmatter header after saving

After running defuddle, prepend the source URL and fetch date:

```bash
SLUG="article-slug-$(date +%Y-%m-%d)"
{ echo "---"; echo "source_url: https://example.com/article"; echo "fetched: $(date +%Y-%m-%d)"; echo "---"; echo ""; defuddle https://example.com/article; } > .raw/articles/$SLUG.md
```

### Clean a local HTML file

```bash
defuddle page.html
```

## When to Use

Use: articles/blogs/docs from URLs with surrounding content, long articles on token budget.
Skip: clean markdown/PDF, dashboards/apps/structured data, defuddle not installed + short article.

## Fallback

If not installed: use WebFetch directly. Content is less clean but workable.

## Integration with /ingest

`/ingest` calls defuddle automatically if available when given a URL. Manual path: run save command above, then `ingest .raw/articles/[slug].md`.
