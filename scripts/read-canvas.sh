#!/usr/bin/env bash
# read-canvas.sh — emit canvas content as structured plain text, stripping layout noise
#
# Usage: read-canvas.sh [--raw] <path-to-canvas-file>
#
# Options:
#   --raw   Output the full raw JSON (no stripping). Useful when position/ID
#           data is needed (e.g. before write operations to avoid collisions).
#
# Output: plain text with groups as ## sections, edges as flat list at the end
# Exit codes: 0 success, 1 bad args, 2 file not found, 3 parse error

set -euo pipefail

RAW=0
CANVAS_FILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --raw) RAW=1; shift ;;
    -*)
      echo "Usage: read-canvas.sh [--raw] <path-to-canvas-file>" >&2
      exit 1
      ;;
    *) CANVAS_FILE="$1"; shift ;;
  esac
done

if [[ -z "$CANVAS_FILE" ]]; then
  echo "Usage: read-canvas.sh [--raw] <path-to-canvas-file>" >&2
  exit 1
fi

if [[ ! -f "$CANVAS_FILE" ]]; then
  echo "Error: file not found: $CANVAS_FILE" >&2
  exit 2
fi

# --raw: emit the full JSON unchanged (useful for write operations that need position data)
if [[ "$RAW" -eq 1 ]]; then
  python3 -c "
import sys, json
path = sys.argv[1]
try:
    with open(path) as f:
        data = json.load(f)
except json.JSONDecodeError as e:
    print(f'Error: failed to parse canvas JSON: {e}', file=sys.stderr)
    sys.exit(3)
print(json.dumps(data, indent=2))
" "$CANVAS_FILE"
  exit $?
fi

python3 - "$CANVAS_FILE" <<'PYEOF'
import sys, json

path = sys.argv[1]
try:
    with open(path) as f:
        data = json.load(f)
except json.JSONDecodeError as e:
    print(f"Error: failed to parse canvas JSON: {e}", file=sys.stderr)
    sys.exit(3)

nodes = data.get("nodes", [])
edges = data.get("edges", [])

# Build lookup: id -> node
by_id = {n["id"]: n for n in nodes}

# Separate groups from content nodes
groups = {n["id"]: n for n in nodes if n.get("type") == "group"}
content_nodes = [n for n in nodes if n.get("type") != "group"]

# Map each content node to its group (the group that contains it, if any)
# A node is "inside" a group if its x,y falls within group bounds
def in_group(node, group):
    nx, ny = node.get("x", 0), node.get("y", 0)
    gx, gy = group.get("x", 0), group.get("y", 0)
    gw, gh = group.get("width", 0), group.get("height", 0)
    return gx <= nx <= gx + gw and gy <= ny <= gy + gh

node_to_group = {}
for node in content_nodes:
    for gid, group in groups.items():
        if in_group(node, group):
            node_to_group[node["id"]] = gid
            break  # assign to first (outermost) match; good enough for flat canvases

# Group content nodes by their group id (or None for ungrouped)
from collections import defaultdict
grouped = defaultdict(list)
for node in content_nodes:
    gid = node_to_group.get(node["id"])
    grouped[gid].append(node)

# Sort groups by their y position (top to bottom) then x (left to right)
sorted_group_ids = sorted(
    groups.keys(),
    key=lambda gid: (groups[gid].get("y", 0), groups[gid].get("x", 0))
)

def node_label(node):
    """Return a short label for use in edge descriptions."""
    # Prefer group label, then first line of text, then id
    if node.get("type") == "group":
        return node.get("label", node["id"])
    text = node.get("text", "").strip()
    if text:
        first_line = text.splitlines()[0].lstrip("#").strip()
        return first_line[:60] + ("…" if len(first_line) > 60 else "")
    return node.get("id", "?")

def render_node(node):
    """Render a single content node as text."""
    ntype = node.get("type", "text")
    if ntype == "text":
        return node.get("text", "").strip()
    elif ntype == "file":
        return f"[file] {node.get('file', '')}"
    elif ntype == "link":
        return f"[link] {node.get('url', '')}"
    else:
        return f"[{ntype}]"

# Emit
canvas_name = path.split("/")[-1].replace(".canvas", "")
print(f"# Canvas: {canvas_name}")
print()

for gid in sorted_group_ids:
    group = groups[gid]
    label = group.get("label", gid)
    print(f"## {label}")
    print()
    # Sort child nodes top-to-bottom
    children = sorted(grouped.get(gid, []), key=lambda n: (n.get("y", 0), n.get("x", 0)))
    for node in children:
        rendered = render_node(node)
        if rendered:
            print(rendered)
            print()

# Ungrouped nodes
ungrouped = grouped.get(None, [])
if ungrouped:
    print("## (ungrouped)")
    print()
    for node in sorted(ungrouped, key=lambda n: (n.get("y", 0), n.get("x", 0))):
        rendered = render_node(node)
        if rendered:
            print(rendered)
            print()

# Edges
if edges:
    print("## Edges")
    print()
    for edge in edges:
        from_node = by_id.get(edge.get("fromNode", ""), {})
        to_node = by_id.get(edge.get("toNode", ""), {})
        from_label = node_label(from_node) if from_node else edge.get("fromNode", "?")
        to_label = node_label(to_node) if to_node else edge.get("toNode", "?")
        edge_label = edge.get("label", "")
        if edge_label:
            print(f"- {from_label} → {to_label} ({edge_label})")
        else:
            print(f"- {from_label} → {to_label}")
PYEOF
