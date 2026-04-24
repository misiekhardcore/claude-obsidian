#!/usr/bin/env bash
# claude-obsidian vault setup script
# Run this ONCE before opening Obsidian for the first time.
# Usage: bin/setup-vault.sh /path/to/vault

set -euo pipefail

if [ -z "${1:-}" ] || [ -z "$1" ]; then
  echo "Error: vault path is required"
  echo ""
  echo "Usage: bin/setup-vault.sh /absolute/path/to/vault"
  echo ""
  echo "Example:"
  echo "  bin/setup-vault.sh /home/user/my-vault"
  echo "  bin/setup-vault.sh /tmp/test-vault"
  exit 1
fi

VAULT="$1"
OBSIDIAN="$VAULT/.obsidian"

# Locate the plugin root. Prefer CLAUDE_PLUGIN_ROOT when set (in-session).
# Otherwise derive it from $0 so standalone invocations work.
if [ -z "${CLAUDE_PLUGIN_ROOT:-}" ]; then
  SCRIPT_PATH=$(readlink -f "$0" 2>/dev/null || python3 -c "import os,sys;print(os.path.realpath(sys.argv[1]))" "$0")
  CLAUDE_PLUGIN_ROOT=$(dirname "$(dirname "$SCRIPT_PATH")")
  export CLAUDE_PLUGIN_ROOT
fi

DEFAULTS_DIR="${CLAUDE_PLUGIN_ROOT}/_obsidian-defaults"

echo "Setting up claude-obsidian vault at: $VAULT"

# ── 1. Create directories ─────────────────────────────────────────────────────
mkdir -p "$OBSIDIAN/snippets"
mkdir -p "$VAULT/.raw"
mkdir -p "$VAULT/wiki/concepts" "$VAULT/wiki/entities" "$VAULT/wiki/sources" "$VAULT/wiki/questions" "$VAULT/wiki/meta"
mkdir -p "$VAULT/_templates"

# ── 2. Copy Obsidian default configs (graph.json, app.json, appearance.json) ──
# These are overwritten on every run so the vault stays in sync with the
# plugin's expected filters and color groups.
if [ ! -d "$DEFAULTS_DIR" ]; then
  echo "Error: defaults directory not found at $DEFAULTS_DIR" >&2
  exit 1
fi

for src in "$DEFAULTS_DIR"/*.json; do
  [ -e "$src" ] || continue
  cp "$src" "$OBSIDIAN/$(basename "$src")"
done

# ── 5. Download Excalidraw main.js (8MB, not in git) ─────────────────────────
EXCALIDRAW="$OBSIDIAN/plugins/obsidian-excalidraw-plugin"
if [ -f "$EXCALIDRAW/manifest.json" ] && [ ! -f "$EXCALIDRAW/main.js" ]; then
  echo "Downloading Excalidraw main.js (~8MB)..."
  curl -sS -L \
    "https://github.com/zsviczian/obsidian-excalidraw-plugin/releases/latest/download/main.js" \
    -o "$EXCALIDRAW/main.js"
  echo "✓ Excalidraw main.js downloaded"
elif [ -f "$EXCALIDRAW/main.js" ]; then
  echo "✓ Excalidraw main.js already present"
fi

echo ""
echo "✓ Setup complete."
echo ""
echo "Next steps:"
echo "  1. Open Obsidian"
echo "  2. Manage Vaults → Open folder as vault → select: $VAULT"
echo "  3. Enable community plugins when prompted (Calendar, Thino, Excalidraw, Banners are pre-installed)"
echo "  4. Install: Dataview, Templater, Obsidian Git  (Settings → Community Plugins)"
echo "  5. Type /wiki in Claude Code to scaffold your knowledge base"
echo ""
echo "Pre-installed plugins:"
echo "  - Calendar (sidebar calendar with word count + task dots)"
echo "  - Thino (quick memo capture)"
echo "  - Excalidraw (freehand drawing + image annotation)"
echo "  - Banners (add banner: to any note frontmatter for header images)"
echo ""
echo "CSS snippets enabled:"
echo "  - vault-colors: color-codes wiki/ folders in file explorer"
echo "  - ITS-Dataview-Cards: use \`\`\`dataviewjs with .cards for card grids"
echo "  - ITS-Image-Adjustments: append |100 to image embeds for sizing"
echo ""
echo "Views available:"
echo "  - Wiki Map canvas (wiki/Wiki Map.canvas) — knowledge graph"
echo "  - Design Ideas canvas (projects/visual-vault/design-ideas.canvas) — visual reference board"
echo "  - Graph view filtered to wiki/ only, color-coded by type"
echo ""
echo "To switch to the visual layout (Canvas + Calendar + Thino sidebar):"
echo "  Quit Obsidian, then run:"
echo "    cp $OBSIDIAN/workspace-visual.json $OBSIDIAN/workspace.json"
echo "  Then reopen Obsidian."
echo ""
echo "Graph colors: if they reset after closing Obsidian, open Graph settings"
echo "→ Color groups and re-add them once. They persist permanently after that."
