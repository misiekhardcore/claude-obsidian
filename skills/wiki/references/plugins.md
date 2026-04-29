# Obsidian Plugins

Only plugins that require user action are listed here. Plugins enabled by default in Obsidian (Properties, Backlinks, Outline, etc.) work out of the box and need no setup.

---

## Core plugins to enable

These ship with Obsidian but are off by default. Enable them in **Settings → Core plugins**.

| Plugin | Why we need it |
|--------|----------------|
| **Bases** | Native database views over `.base` files. Powers `wiki/meta/dashboard.base` and the `obsidian-bases` skill. Requires Obsidian 1.9.10+ (Aug 2025). |

---

## Community plugins to install

Install in **Settings → Community plugins → Browse**.

| Plugin | Why we need it |
|--------|----------------|
| **Templater** | Resolves `<% tp.file.title %>` and `<% tp.date.now(...) %>` in `_templates/*.md` so new notes get auto-populated frontmatter. Without it, new notes ship with raw template syntax. |

---

## Notes

- **Dataview is no longer required.** Bases replaces the legacy `dashboard.md` queries with `dashboard.base`. Dataview can still be installed for personal queries, but no skill in this repo emits Dataview blocks.
- **Obsidian Git is not used.** Vault git history is managed outside the plugin layer.
