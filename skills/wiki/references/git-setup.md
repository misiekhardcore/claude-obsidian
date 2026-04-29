# Git Setup

Initialize git in the vault to get full history and protect against bad writes.

---

## Initialize

```bash
cd "$VAULT_PATH"
git init
git add -A
git commit -m "Initial vault scaffold"
```

---

## .gitignore

The root `.gitignore` in this repo already covers the right exclusions:

```
.obsidian/workspace.json
.obsidian/workspace-mobile.json
.smart-connections/
.trash/
.DS_Store
```

`workspace.json` changes constantly as you move panes around. Excluding it keeps the diff clean.

---

## Remote (Optional)

To back up to GitHub:

```bash
git remote add origin https://github.com/yourname/your-vault
git push -u origin main
```

Keep the repo private if the vault contains personal notes.
