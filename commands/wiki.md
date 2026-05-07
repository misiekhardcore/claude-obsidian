---
description: Bootstrap or check the claude-obsidian wiki vault. Use `/wiki init` to seed the vault from the configured path; `/wiki` (no args) runs the scaffold workflow.
argument-hint: "[init]"
---
Run `wiki` skill.

**`/wiki init`** — Seed vault: `bash "${CLAUDE_PLUGIN_ROOT}/bin/wiki-init.sh" "${user_config.vault_path}"`. Handles directories, Obsidian config, templates. Surface stdout.

**`/wiki`** (SCAFFOLD):
1. Check Obsidian 1.12.7+ installed (offer install if not; see `skills/wiki/references/plugins.md`).
2. Check vault exists (look for `.obsidian/`). Report state if yes.
3. Check vault registered with CLI (`obsidian list vaults`). Point at `skills/wiki/references/cli-setup.md` if not.
4. Ask ONE question: "What is this vault for?"

Scaffold entire wiki structure. Show what created. Ask: "Adjust anything before we start?"

If already set up: report recent ingests and offer to continue.
