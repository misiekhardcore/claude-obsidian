# Vault Operations Reference

Single source of truth for technical patterns and cross-skill vault I/O.
Refer to this file instead of duplicating patterns in skill bodies.

## 1. Obsidian CLI Patterns
All vault operations must use the `obsidian` CLI (routed via `scripts/obsidian-cli.sh`).

### Standard Verbs
|Verb|Usage|Output|
|-|-|-|
|`read`|`path=wiki/hot.md`|Plain text|
|`create`|`path=wiki/concepts/foo.md content="..."`|`Created: <path>`|
|`append`|`file=wiki/log.md content="..."`|`Appended to: <path>`|
|`prepend`|`file=wiki/index.md content="..."`|`Prepended to: <path>`|
|`property:set`|`name=updated value=... path=...`|plain text|
|`property:read`|`name=updated path=...`|plain text (value only)|
|`properties`|`path=...`|YAML block (all properties)|

**Multiline Content:** Use `\n` for newlines.
**Bypass:** Use direct FS `Read`/`Write` only for `.raw/`, `_attachments/images/**`, or `.canvas` files (see `cli.md` §6–7).

## 2. The Slugification Pipeline
Never hand-craft slugs. Always use the `slug.sh` script to ensure Unicode normalization and separator collapsing.

```bash
# Pattern: Title/URL -> Slug
slug=$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/slug.sh" "<input_string>")
```

## 3. Indexing & Log Patterns

### Index Section Insertion
Use the read-splice-overwrite pattern via `scripts/index-section-insert.sh`.
- **Target:** `wiki/index.md`
- **Entry Format:** `- [[<slug>|<Display Name>]] — <one-line description>`
- **Logic:** Inserts immediately after the matching heading (e.g., `## Concepts`).

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/index-section-insert.sh" \
  wiki/index.md "$section_heading" "$new_entry"
```

### Log Prepending
New entries always go to the TOP of `wiki/log.md`.
```bash
obsidian prepend file=wiki/log.md content="## [YYYY-MM-DD] <op> | <title>\n- <details>\n\n"
```

## 4. Hot Cache Protocol
Maintain `wiki/hot.md` after every operation.
- **Format:** Follow `${CLAUDE_PLUGIN_ROOT}/_shared/hot-cache-protocol.md`.
- **Operation:** Overwrite existing content to keep it a concise (~500 word) summary of recent state.

## 5. Enforcement Gap — Hook Scope

The `PreToolUse` hook intercepts `Bash` only. It never fires on `Read`, `Write`, `Edit`, `Glob`, or `Grep` tool calls. This means:

- **Agents and skills must not list `Read`, `Glob`, or `Grep` for vault access.** Without `Bash`, the obsidian CLI hook never applies and the agent can only bypass it.
- **`Write`/`Edit` tool calls on vault paths bypass the CLI preflight** (app-running check, vault-open check). Vault writes must go through `obsidian create`/`obsidian append` via Bash.
- **PostToolUse auto-commit covers both paths:** the `Write|Edit` matcher fires when the Write/Edit tool is used; the `Bash` matcher fires (via `log-obsidian-calls.sh`) for mutating obsidian verbs (`create`, `append`, `prepend`, `create-or-append`, `property:set`, `property:remove`, `eval`).
- **Legitimate bypasses** (direct `Read`/`Write`): `.raw/` source files, `_attachments/images/**`, `.canvas` files (see `cli.md` §6–7).
