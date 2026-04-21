---
description: Bootstrap or check the claude-obsidian wiki vault. Use `/wiki init` to seed the vault from the configured path; `/wiki` (no args) runs the scaffold workflow.
argument-hint: "[init]"
---

Read the `wiki` skill.

If the argument is `init`, run the **INIT** operation below. Otherwise, run the **SCAFFOLD** workflow described in the skill.

## INIT

Seed the configured Obsidian vault. One-shot, idempotent; does not scaffold the knowledge base (that is `/wiki`).

Run:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/bin/wiki-init.sh" "${user_config.vault_path}"
```

The script handles everything:

- If `${user_config.vault_path}` is empty, prints `Configure vault path first: enable the plugin and enter your vault path when prompted` and exits 0.
- Delegates to `bin/setup-vault.sh` (vault directories + Obsidian config) and `bin/copy-templates.sh` (idempotent template copy).
- Prints the next steps (open Obsidian, install Dataview/Templater/Obsidian Git, run `/wiki` to scaffold).

Surface the script's stdout to the user verbatim.

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
