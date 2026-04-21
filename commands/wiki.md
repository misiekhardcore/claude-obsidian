---
description: Bootstrap or check the claude-obsidian wiki vault. Use `/wiki init` to seed the vault from the configured path; `/wiki` (no args) runs the scaffold workflow.
argument-hint: "[init]"
---

Read the `wiki` skill.

If the argument is `init`, run the **INIT** operation below. Otherwise, run the **SCAFFOLD** workflow described in the skill.

## INIT

1. Resolve the vault path from `${user_config.vault_path}`. If it is empty, print exactly this line and stop without error:

   ```
   Configure vault path first: enable the plugin and enter your vault path when prompted
   ```

2. Run the setup script:

   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}/bin/setup-vault.sh" "${user_config.vault_path}"
   ```

3. Copy the plugin's `_templates/` into the vault, skipping existing files so the step is idempotent:

   ```bash
   mkdir -p "${user_config.vault_path}/_templates"
   for src in "${CLAUDE_PLUGIN_ROOT}/_templates/"*.md; do
     dst="${user_config.vault_path}/_templates/$(basename "$src")"
     [ -e "$dst" ] || cp "$src" "$dst"
   done
   ```

4. Print next steps:

   - Open Obsidian → *Manage Vaults* → *Open folder as vault* and select `${user_config.vault_path}`.
   - Enable community plugins when prompted, then install **Dataview**, **Templater**, and **Obsidian Git** from Settings → Community Plugins.
   - Run `/wiki` to scaffold your knowledge base.

Re-running `/wiki init` must be idempotent: `setup-vault.sh` already guards existing files, and `cp -n` skips templates that are already in the vault.

## SCAFFOLD (default)

1. Check if Obsidian is installed. If not, offer to install it (see `skills/wiki/references/plugins.md`).
2. Check if this directory has a vault (look for `.obsidian/` folder). If yes, report current vault state.
3. Check if the MCP server is configured (`claude mcp list`). If not, ask if the user wants to set it up.
4. Ask ONE question: "What is this vault for?"

Then build the entire wiki structure based on the answer. Don't ask more questions. Scaffold it, show what was created, and ask: "Want to adjust anything before we start?"

Examples of what the user might say:
- "Map the architecture of github.com/org/repo"
- "Build a sitemap and content analysis for example.com"
- "Track my SaaS business — product, customers, metrics, roadmap"
- "Research project on [topic] — papers, concepts, open questions"
- "Personal second brain — health, goals, learning, projects"
- "Organize my YouTube channel — transcripts, topics, tools mentioned"
- "Executive assistant brain — meetings, tasks, business context"

If the vault is already set up, skip to checking what has been ingested recently and offering to continue where things left off.
