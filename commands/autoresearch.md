---
description: Autonomous iterative research loop. Searches the web, dispatches agents to fetch and synthesize sources, and files everything into the wiki as structured pages.
---
Run the `autoresearch` skill for the given topic or ask "What topic should I research?"

Usage: `/autoresearch [topic]` or `/autoresearch`

First, read `skills/autoresearch/references/program.md` for research constraints. Skill dispatches sub-agents to parallelize search/fetch/synthesis. After agents finish, update wiki index/log/hot.md. Report pages created, key findings, trail page path.

If no vault: "No wiki vault found. Run /wiki first to set one up."
