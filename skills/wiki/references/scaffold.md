# SCAFFOLD Procedure

User describes vault purpose → Execute:

1. Ask: "What is this vault for?" (one question, then proceed).
2. Scaffold flat folders under `wiki/`: `concepts/`, `entities/`, `sources/`, `solutions/`, `comparisons/`, `questions/`. No per-folder `_index.md`.
3. Create `wiki/index.md`, `wiki/log.md`, `wiki/hot.md`.
4. Create `notes/` and copy `_seed/notes/index.md` if missing.
5. Create `daily/` and copy `_seed/daily/example-daily.md` if directory is missing.
6. Create `_templates/` files for each note type.
7. Create `.obsidian/snippets/vault-colors.css` with standard callout styles.
8. Create vault `CLAUDE.md` pointing agents at the vault.
9. Initialize git (`git init && git add -A && git commit -m "Initial vault scaffold"`).
10. Present structure and ask: "Want to adjust anything before we start?"
