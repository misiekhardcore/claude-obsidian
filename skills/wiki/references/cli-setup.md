# Obsidian CLI Setup

The claude-obsidian plugin uses the **Obsidian CLI** to read and write vault notes directly. The CLI ships with Obsidian 1.12.7+, requires no plugins, and survives Obsidian restarts.

---

## Prerequisites

- **Obsidian 1.12.7 or later** (2026 or later). Check your version: **Obsidian > About**.
- **Obsidian must be running** with your vault open. The CLI is a desktop-app IPC channel; it communicates via the running process.
- The Obsidian binary must be on your `PATH` (or invoked via Flatpak — see below).

---

## Step 1: Verify the CLI is Available

Check if the `obsidian` command works on your machine:

```bash
obsidian version
```

Expected output:
```
1.12.7 (installer 1.12.7)
```

**If `obsidian: command not found`:**

**Linux (Flatpak):** The Flatpak build sandboxes the binary. Invoke it as:
```bash
flatpak run md.obsidian.Obsidian --cli version
```

To simplify, create an alias in your shell config:
```bash
alias obsidian='flatpak run md.obsidian.Obsidian --cli'
```

**macOS / Windows:** Reinstall Obsidian from https://obsidian.md/download and ensure it's in `PATH`.

---

## Step 2: Register Your Vault

The Obsidian CLI needs to know your vault's location. Open Obsidian and do this **once per vault**:

1. **Obsidian > Settings > About > Vault location** — copy the absolute path (e.g., `/home/you/Obsidian/MyVault`)
2. **Terminal:**
   ```bash
   obsidian register vault=/absolute/path/to/vault
   ```
   Expected output: `Vault registered.`

**Verify registration:**
```bash
obsidian list vaults
```

Your vault should appear in the list.

---

## Step 3: Sanity Check

With Obsidian still running and the vault open, test the CLI:

```bash
obsidian read path=wiki/hot.md
```

You should see the contents of `wiki/hot.md` (or an error if the file doesn't exist yet, which is fine).

If you get **`Vault not found.`**, double-check:
1. Obsidian is still running
2. The vault path in the register step was an absolute path (not relative)
3. The vault name you passed matches the registered vault name exactly

---

## Common Operations

Once registered, all vault operations go through the CLI:

```bash
# Read a file
obsidian read path=wiki/index.md

# Create a new file
obsidian create path=wiki/concepts/my-note.md content="# My Note\n\nContent here."

# Append to a file
obsidian append path=wiki/index.md content="- New entry"

# Search for content
obsidian search query="machine learning"

# List files in a folder
obsidian outline path=wiki/

# List all tags
obsidian tags
```

For a complete reference of all commands and options, see `${CLAUDE_PLUGIN_ROOT}/_shared/cli.md`.

---

## When the CLI is Unavailable

If Obsidian is closed or the CLI is not installed:

**Cron-time vault writes:** The CLI requires Obsidian to be running. For scheduled tasks (e.g., weekly `wiki-lint`), see `bin/wiki-lint-cron.sh` for direct-file fallback behavior.

**Troubleshooting steps:**
1. Start Obsidian and open your vault
2. Verify `obsidian version` returns a version string (not empty, not "command not found")
3. Confirm your vault is registered: `obsidian list vaults`
4. Re-run your vault operation

---

## Examples

TBD — follow-up PR #52 will add practical examples (ingest a source, query the wiki, etc.).

---

## See Also

- `${CLAUDE_PLUGIN_ROOT}/_shared/cli.md` — empirical CLI contract (exit codes, error patterns, escape hatches)
- `${CLAUDE_PLUGIN_ROOT}/CLAUDE.md` — agent-facing plugin docs (vault structure, skill overview)
