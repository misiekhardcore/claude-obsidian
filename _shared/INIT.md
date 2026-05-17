# claude-obsidian — session init

This session has an Obsidian vault configured by the `claude-obsidian` plugin. The vault is a knowledge base, not a code directory.

## When to engage the vault

- The user asks a question that prior notes might answer → `/query`.
- The user wants to file something for later → `/note`, `/daily`, `/save`.
- The user mentions vault / wiki / notes / daily / ingest / research / lint / canvas.

## When NOT to engage the vault

General coding, build, or test work in the current repo. Do not read the vault for routine code questions — the wiki is for synthesized knowledge, not for re-deriving things from source.

## Vault I/O

All vault reads and writes go through the `obsidian` CLI via Bash. Direct `Read`/`Write`/`Edit` on vault paths is hook-blocked and will be denied with a CLI redirect in the deny reason. Before any vault interaction, read the canonical operational reference:

[Vault Operations Reference](${CLAUDE_PLUGIN_ROOT}/_shared/vault-ops.md)

It covers verb selection, the slugification pipeline, indexing/log/hot-cache protocols, active enforcement, and the canonical bypass list (binary files, canvas, JSON admin artifacts).
