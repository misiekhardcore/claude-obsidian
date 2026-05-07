# Canvas Specification

Technical guide for `.canvas` JSON files.

## Coordinate System
- **Origin (0,0)**: Center of viewport.
- **Axis**: X increases right; Y increases downward (more negative = higher up).
- **Anchor**: `x` and `y` refer to the **top-left corner** of the node.

## Node Types
|Type|Key Fields|Usage|
|-|-|-|
|**text**|`text` (markdown)|Styled cards. Min size: 200x60.|
|**file**|`file` (vault-path)|Images, PDFs, notes.|
|**group**|`label`, `color`|Visual zones. Purely aesthetic; no parent-child logic.|
|**link**|`url` (https)|Web previews via Open Graph.|

## Edges (Connections)
- **Required**: `id`, `fromNode`, `toNode`.
- **Defaults**: `fromEnd: "none"`, `toEnd: "arrow"`.
- **Sizing**: Use `color` ("1"–"6") to match node themes.

## Asset Sizing Guidelines
|Aspect Ratio|Condition|Width|Height|
|-|-|-|-|
|16:9 (wide)|1.6–2.0|420|236|
|4:3|1.2–1.6|380|285|
|1:1 (sq)|0.9–1.1|280|280|
|PDF|Any|400|520|

## Implementation Notes
- **IDs**: Use 16-char hex or descriptive IDs (e.g., `text-title-01`).
- **Paths**: Must be vault-relative (e.g., `_attachments/images/foo.png`).
- **Sizing**: Use `identify` or PIL to get actual dimensions before placing.
