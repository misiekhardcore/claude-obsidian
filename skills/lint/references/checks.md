# Lint Checks

Lint agent runs checks #1, #2, #6–#16 in order (no checks #3–#5). Each check's source, logic, and auto-fix policy:

|#|Check|Source|Auto-fix|
|-|-|-|-|
|1|Missing frontmatter|JSON|Safe|
|2|Stub pages (<50 words)|JSON|Safe|
|6|Dead links (404)|obsidian CLI|Safe|
|7|Orphan pages (no backlinks)|JSON|Review|
|8|Duplicate title|obsidian CLI|Review|
|9|Missing wikilink targets|obsidian CLI|Safe|
|10|Frontmatter gaps|JSON|Safe|
|11|Broken embeds|obsidian CLI|Safe|
|12|Empty sections|page read|Review|
|13|Orphan images|find|Review|
|14|Tag consistency|obsidian properties|Review|
|15|Naming conventions|obsidian CLI|Review|
|16|Trail integrity|page read|Never|

Checks #1, #2, #7, #10 read from lint JSON; others use `obsidian` CLI or page reads.
