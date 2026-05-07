# Visual Customization

Apply during scaffold. This makes the file explorer color-coded by folder type and adds custom callout styles.

## CSS Snippet

Create this file at `.obsidian/snippets/vault-colors.css` inside the vault:

```css
:root {
  --wiki-1: #4fc1ff;
  --wiki-2: #c586c0;
  --wiki-3: #dcdcaa;
  --wiki-4: #ce9178;
  --wiki-5: #6a9955;
  --wiki-6: #d16969;
  --wiki-7: #569cd6;
}

/* Folder colors in file explorer */
.nav-folder-title[data-path^="wiki/domains"] {
  color: var(--wiki-1);
}
.nav-folder-title[data-path^="wiki/entities"] {
  color: var(--wiki-2);
}
.nav-folder-title[data-path^="wiki/concepts"] {
  color: var(--wiki-3);
}
.nav-folder-title[data-path^="wiki/sources"] {
  color: var(--wiki-4);
}
.nav-folder-title[data-path^="wiki/questions"] {
  color: var(--wiki-5);
}
.nav-folder-title[data-path^="wiki/comparisons"] {
  color: var(--wiki-6);
}
.nav-folder-title[data-path^="wiki/meta"] {
  color: var(--wiki-7);
}
.nav-folder-title[data-path=".raw"] {
  color: #808080;
  opacity: 0.6;
}

/* Custom callouts */
.callout[data-callout="contradiction"] {
  --callout-color: 209, 105, 105;
  --callout-icon: lucide-alert-triangle;
}
.callout[data-callout="gap"] {
  --callout-color: 220, 220, 170;
  --callout-icon: lucide-help-circle;
}
.callout[data-callout="key-insight"] {
  --callout-color: 79, 193, 255;
  --callout-icon: lucide-lightbulb;
}
.callout[data-callout="stale"] {
  --callout-color: 128, 128, 128;
  --callout-icon: lucide-clock;
}
```

## Enable the Snippet

Tell the user: Settings > Appearance > CSS Snippets > open folder > paste the file > click the refresh icon > toggle it on.

## Graph View Groups

Set in Graph View settings (gear icon):

| Query | Color |
| `path:wiki/domains` | Blue |
| `path:wiki/entities` | Purple |
| `path:wiki/concepts` | Yellow |
| `path:wiki/sources` | Orange |
| `path:wiki/questions` | Green |
| `path:.raw` | Gray (dimmed) |

## Custom Callouts

Four custom types (render with vault-colors.css only; fall back to default without):

| Callout | Icon | Use |
| `contradiction` | alert-triangle | New source conflicts existing claim |
| `gap` | help-circle | Topic missing source |
| `key-insight` | lightbulb | Important takeaway |
| `stale` | clock | Claim outdated (old source) |

### Usage

Use these in wiki pages to flag important states:

```markdown
> [!contradiction] Title [[Page A]] claims X. [[Page B]] says Y. Needs resolution.

> [!gap] Title This topic has no source yet. Consider finding one.

> [!key-insight] Title The most important takeaway from this section.

> [!stale] Title This claim may be outdated. Source was from 2022.
```

Why custom: map wiki concepts not in defaults. contradiction=conflict (not generic warning). gap=missing source (not generic question). key-insight=top takeaway (not generic tip). stale=time decay (no built-in).

Replacements: contradiction→warning, gap→question, key-insight→tip, stale→warning.

## Minimal Theme (Recommended)

Best with Minimal theme. Install: Settings > Appearance > Manage > search "Minimal".
