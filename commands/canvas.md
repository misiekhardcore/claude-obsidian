---
description: Open, create, or update a visual canvas — add images, text, PDFs, wiki pages, and banana-generated assets to Obsidian canvas files.
argument-hint: "[new|add image|add text|add pdf|add note|zone|list|from banana]"
---
Run the `canvas` skill matching user command:

|Command|Action|
|-|-|
|`/canvas`|Status: node counts, zones, instructions|
|`/canvas new [name]`|Create named canvas in wiki/canvases/|
|`/canvas add image [path]`|Add image (download URL or copy external)|
|`/canvas add text [content]`|Add text card|
|`/canvas add pdf [path]`|Add PDF node|
|`/canvas add note [page]`|Add wiki page card|
|`/canvas zone [name] [color]`|Add labeled zone|
|`/canvas list`|List all canvases with counts|
|`/canvas from banana`|Find recent generated images and add|

Default: `wiki/canvases/main.canvas`. Create if missing.
