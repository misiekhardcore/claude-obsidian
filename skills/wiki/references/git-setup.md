# Git Setup

Initialize git in vault for history + safety.

```bash
cd "$VAULT_PATH"
git init && git add -A && git commit -m "Initial vault scaffold"
```

.gitignore already covers: workspace.json (changes constantly), workspace-mobile.json, .smart-connections/, .trash/, .DS_Store.

Optional remote backup:
```bash
git remote add origin https://github.com/yourname/vault
git push -u origin main
```
Keep private if vault contains personal notes.
