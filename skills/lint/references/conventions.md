# Naming & Style Conventions

## Filenames

- Lowercase kebab-case only
- Max 40 chars via slug.sh

## Folders

- Lowercase plural: `concepts/`, `entities/`, `sources/`

## Tags

- Lowercase kebab-case
- No spaces

## Wikilinks

- `[[page-name]]` — no surrounding spaces inside brackets
- No URL-as-wikilink (`[[https://...]]` — flagged as anti-pattern)

## Frontmatter

- Flat YAML per `_shared/frontmatter.md`
- `type`, `title`, `created`, `updated`, `tags` required
- `confidence`, `evidence`, `related`, `sources` for polished pages only
