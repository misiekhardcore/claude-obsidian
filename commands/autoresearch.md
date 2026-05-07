---
description: Autonomous iterative research loop. Searches the web, dispatches agents to fetch and synthesize sources, and files everything into the wiki as structured pages.
---
Read the `autoresearch` skill. Then run the research loop.

Usage:

- `/autoresearch [topic]` — research a specific topic
- `/autoresearch` — ask "What topic should I research?"

Before starting, read `skills/autoresearch/references/program.md` to load the research constraints and objectives.

If no vault is set up yet, say: "No wiki vault found. Run /wiki first to set one up."

The skill dispatches sub-agents (`agents/research-round.md`, `agents/source-synth.md`) to parallelize search, fetch, and synthesis cycles. After all agents finish, update wiki/index.md, wiki/log.md, and wiki/hot.md.

Report how many pages were created, the key findings, and the trail page path.
