---
name: obsidian-markdown
description: Obsidian Flavored Markdown syntax. Wikilinks, embeds, callouts, properties, tags, math.
allowed-tools: Read Write Edit
---
# obsidian-markdown

Reference when writing any wiki page. Obsidian Markdown: wikilinks, embeds, callouts, properties. Prefer kepano/obsidian-skills plugin if installed. Otherwise use reference below.

## Wikilinks

Internal links use double brackets. The filename without extension.

|Syntax|What it does|
|-|-|
|`[[Note Name]]`|Basic link|
|`[[Note Name\|Display Text]]`|Aliased link (shows "Display Text")|
|`[[Note Name#Heading]]`|Link to a specific heading|
|`[[Note Name#^block-id]]`|Link to a specific block|

Rules:

- Case-sensitive on some systems. Match the exact filename.
- No path needed: Obsidian resolves by filename uniqueness.
- If two files have the same name, use `[[Folder/Note Name]]` to disambiguate.

## Embeds

Embeds use `!` before the wikilink. They display the content inline.

|Syntax|What it does|
|-|-|
|`![[Note Name]]`|Embed a full note|
|`![[Note Name#Heading]]`|Embed a section|
|`![[image.png]]`|Embed an image|
|`![[image.png\|300]]`|Embed image with width 300px|
|`![[document.pdf]]`|Embed a PDF (Obsidian renders natively)|
|`![[audio.mp3]]`|Embed audio|

## Callouts

Callouts are blockquotes with a type keyword. They render as styled alert boxes.

```markdown
> [!note] Default informational callout.

> [!note] Custom Title Callout with a custom title.

> [!note]- Collapsible (closed by default) Click to expand.

> [!note]+ Collapsible (open by default) Click to collapse.
```

### All callout types

|Type|Aliases|Use for|
|-|-|-|
|`note`|:|General notes|
|`abstract`|`summary`, `tldr`|Summaries|
|`info`|:|Information|
|`todo`|:|Action items|
|`tip`|`hint`, `important`|Tips and highlights|
|`success`|`check`, `done`|Positive outcomes|
|`question`|`help`, `faq`|Open questions|
|`warning`|`caution`, `attention`|Warnings|
|`failure`|`fail`, `missing`|Errors or failures|
|`danger`|`error`|Critical issues|
|`bug`|:|Known bugs|
|`example`|:|Examples|
|`quote`|`cite`|Quotations|
|`contradiction`|:|Conflicting information (wiki convention)|

## Properties (Frontmatter)

Obsidian renders YAML frontmatter as a Properties panel. Rules:

```yaml
---
type: concept # plain string
title: "Note Title" # quoted if it contains special chars
created: 2026-04-08 # date as YYYY-MM-DD (not ISO datetime)
updated: 2026-04-08
tags:
  - tag-one # list items use - format
  - tag-two
status: developing
related:
  - "[[Other Note]]" # wikilinks must be quoted in YAML
sources:
  - "[[source-page]]"
---
```

Rules:

- Flat YAML only. Never nest objects.
- Dates as `YYYY-MM-DD`, not `2026-04-08T00:00:00`.
- Lists as `- item`, not inline `[a, b, c]`.
- Wikilinks in YAML must be quoted: `"[[Page]]"`.
- `tags` field: Obsidian reads this as the tag list, searchable in vault.

## Tags

Two valid forms:

```markdown
#tag-name : inline tag anywhere in the body #parent/child-tag : nested tag (shows hierarchy in tag pane)
```

In frontmatter:

```yaml
tags:
  - research
  - ai/obsidian
```

Do not use `#` inside frontmatter tag lists. Just the tag name.

## Text Formatting

Standard Markdown plus Obsidian extensions:

|Syntax|Result|
|-|-|
|`**bold**`|Bold|
|`*italic*`|Italic|
|`~~strikethrough~~`|Strikethrough|
|`==highlight==`|Highlighted text (yellow in Obsidian)|
|`` `inline code` ``|Inline code|

## Math

Obsidian uses MathJax/KaTeX:

Inline math:

```markdown
$E = mc^2$
```

Block math:

```markdown
$$
\int_0^\infty e^{-x} dx = 1
$$
```

## Code Blocks

Standard fenced code blocks. Obsidian highlights all common languages:

````markdown
```python
def hello():
    return "world"
```
````

## Tables

Standard Markdown tables:

```markdown
| Column A | Column B | Column C |
| -------- | -------- | -------- |
| Value    | Value    | Value    |
| Value    | Value    | Value    |
```

Obsidian renders tables natively. No plugin needed.

## Mermaid Diagrams

Obsidian renders Mermaid natively:

````markdown
```mermaid
graph TD
    A[Start] --> B{Decision}
    B -->|Yes| C[End]
    B -->|No| D[Loop]
    D --> A
```
````

Supported: `graph`, `sequenceDiagram`, `gantt`, `classDiagram`, `pie`, `flowchart`.

## Footnotes

```markdown
This sentence has a footnote.[^1]

[^1]: The footnote text goes here.
```

## Do NOT Do

- Don't use `[text](path.md)` for internal links; use `[[Note Name]]`
- Don't use HTML inside callouts
- Don't use `##` inside callout body
- Don't write `tags: [a,b,c]` inline; use list format
- Don't use ISO datetime in frontmatter; use `YYYY-MM-DD`
