# CLI Contract

Empirical reference for the Obsidian CLI used by every claude-obsidian skill. All behaviors are verified by `scripts/cli-spike.sh` against a live vault; captures live in `tests/spike-results/`.

Read this file when a skill needs to invoke vault operations, understand output formats, or handle errors. Do not preload — read on demand.

---

## 1. Invocation contract

All vault operations go through `scripts/obsidian-cli.sh`, not the raw `obsidian` binary directly. A PreToolUse Bash hook (`hooks/obsidian-cli-rewrite.sh`) rewrites bare `obsidian <verb> ...` Bash invocations to the wrapper transparently, but skills should call the wrapper explicitly.

```bash
# Direct wrapper call (preferred in skill code)
"${CLAUDE_PLUGIN_ROOT}/scripts/obsidian-cli.sh" read path=wiki/hot.md

# Raw form (rewritten to wrapper by the hook)
obsidian read path=wiki/hot.md
```

**vault= is name-only.** The CLI's `vault=` parameter accepts the vault's display name (basename of the vault path), not a path. Passing a path returns `"Vault not found."` The wrapper derives the name via `basename "$VAULT"` automatically — skills never pass `vault=` directly.

**Obsidian must be running with the vault open.** The CLI is a desktop-app IPC channel; it requires the Obsidian process to be active. The SessionStart hook probes `obsidian version` at startup and emits an actionable warning if Obsidian is not reachable (fail-soft: session continues).

**All output (including errors) goes to stdout.** stderr is always empty from the upstream CLI. The wrapper inspects stdout's first line to normalize the exit code.

---

## 2. Exit-code table

The upstream CLI always returns exit 0. The wrapper normalizes:

| Code | Meaning | stdout first-line pattern |
|------|---------|--------------------------|
| 0 | Success | Any non-error output, or empty stdout |
| 1 | Generic CLI error | `Error: ...` |
| 2 | Vault not found | `Vault not found.` |
| 3 | Pre-flight failed | (wrapper emits to stderr; binary missing or Obsidian not running) |
| 4 | Vault resolution failed | (wrapper emits to stderr; `resolve-vault.sh` exited non-zero) |

Hooks that want fail-soft behavior chain `|| exit 0`. Skills that need to act on errors check `$?` after the call.

**Known error patterns detected as exit 1:**

| Error message (stdout) | Trigger |
|------------------------|---------|
| `Error: File "<path>" not found.` | `read`/`append`/`prepend` against a missing file |
| `Error: Command "<verb>" not found. ...` | Unknown verb or bad `command id=` |
| `Error: No active file. Use file=<name> or path=<path> to specify a file.` | Verb called with neither `file=` nor `path=` |

---

## 3. Format defaults

Locked by the empirical spike. Skills must not override these without a documented reason.

| Verb | Output format | Notes |
|------|--------------|-------|
| `read` | plain text | File contents verbatim |
| `create` | `Created: <path>` | Confirmation line; use `overwrite` flag to replace existing |
| `append` | `Appended to: <path>` | Confirmation line |
| `prepend` | `Prepended to: <path>` | Confirmation line |
| `backlinks` | **json** | Override from CLI default (tsv). Array of `{"file": "<path>"}` |
| `unresolved` | **json** | Array of `{"link": "<link-text>"}` |
| `search` | json | Array of match objects |
| `search:context` | plain text | Contextual snippets |
| `orphans` | plain text | One vault-relative path per line; **no format=json support** |
| `deadends` | plain text | One vault-relative path per line; **no format=json support** |
| `tasks` | plain text | Markdown task-list lines; **no format=json support** |
| `tags` | plain text | One tag per line (with `#` prefix); **no format=json support** |
| `properties` | plain text | YAML frontmatter block; **no format=json support** |
| `bases` | plain text | One `.base` path per line |
| `commands` | plain text | One `plugin:command-id` per line |
| `outline` | plain text | Heading hierarchy |
| `create-or-append` | plain text | **Wrapper-only** verb — see §3.1 |
| `frontmatter-set` | plain text | **Wrapper-only** verb — see §3.2 |

**Multiline `content=`:** `\n` and `\t` escapes in `content=` values round-trip correctly (verified by spike `ingest-create-multiline`). Use `\n` for newlines in `create`, `append`, `prepend`.

**`content=` escape asymmetry (verified empirically, 2026-05-02):** The parser recognizes `\n` → newline and `\t` → tab, but does **not** recognize `\\` → literal backslash. As a result, content that must preserve literal backslash sequences (e.g. canvas JSON with `\n` in text fields, Markdown code blocks with shell escape sequences) cannot round-trip through `content=` — every `\n` becomes a real newline regardless of preceding backslashes. For these files, use the `eval` escape hatch instead:

```bash
# Escape hatch: bypass content= for files with literal backslash sequences
obsidian eval code="await app.vault.adapter.write('path/to/file', '<full content>');"
# Requires: content embedded in JS string literal (double-quote escaping applies)
# Why eval and not create: content= asymmetric escape parser corrupts \n sequences
```

---

### 3.1 `create-or-append` (wrapper-only)

`create-or-append` collapses the "probe-then-write-or-append" pattern into a single atomic call. It exists so callers (notably `/daily`) never read-modify-overwrite a file at the model layer, which is the root cause of issue #98.

```bash
obsidian create-or-append \
  file=daily/YYYY-MM-DD.md \
  template="---\ntype: daily\ndate: YYYY-MM-DD\ncreated: YYYY-MM-DD\nupdated: YYYY-MM-DD\n---\n\n## Captures\n" \
  content="- HH:MM <verbatim text>"
```

| Aspect | Behavior |
|--------|---------|
| File missing | Writes `template` via `obsidian create`, then appends `content`. |
| File exists | Appends `content` only; `template` is ignored. |
| `template=` | **Required.** No caller in the codebase needs an empty template; YAGNI. |
| Output (missing → created) | `Created and appended: <path>` |
| Output (exists → append) | `Appended to: <path>` |
| Exit | 0 success; 1 if any underlying `create` or `append` fails. |

The verb does **not** read the file body and does **not** touch frontmatter. Use `frontmatter-set` (§3.2) for frontmatter mutations like bumping `updated:`.

### 3.2 `frontmatter-set` (wrapper-only)

`frontmatter-set` performs a surgical mutation of a single YAML scalar key in a file's frontmatter block. The body is preserved byte-for-byte — the awk parser inside the wrapper passes the body through unmodified.

```bash
obsidian frontmatter-set \
  path=daily/YYYY-MM-DD.md \
  key=updated \
  value=YYYY-MM-DD
```

| Aspect | Behavior |
|--------|---------|
| Key present | Replace its value on the first occurrence in the frontmatter block. |
| Key absent | Insert `key: value` on the line before the closing `---`. |
| Body | Untouched. Bullets, headings, code fences are passed through verbatim. |
| Output | `Set frontmatter: <path>` |
| Exit | 0 success; 1 if the file is missing, has no opening `---`, or has no closing `---`. |

**Out of scope (errors silently or behaves naively):** multi-line YAML values (folded `>`, literal `|`), quoted strings whose content includes `:`, nested mappings. The verb assumes a flat YAML header per `${CLAUDE_PLUGIN_ROOT}/_shared/capture-pipeline.md` §2.

**Internal write path:** `frontmatter-set` writes back via `obsidian create overwrite=true`. This is invoked from inside the wrapper, so the `daily/*.md` antipattern guard in `hooks/obsidian-cli-rewrite.sh` (which only inspects model-issued Bash commands) does not trigger.

---

## 4. Escape-hatch policy

In increasing order of risk:

1. **`obsidian-cli.sh command id=<command-id>`** — runs any registered Obsidian command (same IDs as the command palette). Discover with `obsidian-cli.sh commands filter=<prefix>`. Freely allowed. Returns plain text; exit 1 if the command ID is not found.

2. **`obsidian-cli.sh eval code=<js>`** — executes arbitrary JavaScript in Obsidian's renderer process. **Last resort only.** Every call site must carry a one-line comment explaining why neither a structured verb nor `command id=` was sufficient. Reviewer must confirm. Behavior across Obsidian versions is not guaranteed.

3. **Direct `Read`/`Write`/`Edit` on vault paths** — reserved for the documented exceptions in §6. Do not use for ordinary vault operations; file the gap if a CLI verb is missing.

---

## 5. Cron-time behavior

The CLI requires Obsidian to be running. Cron invocations from a closed-laptop context therefore fail at the pre-flight step (exit 3).

`bin/wiki-lint-cron.sh` (issue #52) must document a direct-file-op fallback for this case. Until #52 ships, cron vault access is not supported via the wrapper; callers must handle exit 3 explicitly or avoid vault writes in cron context.

---

## 6. Documented exceptions

The following paths bypass the CLI intentionally. Each bypass is load-bearing; do not remove without verifying the call sites.

| Path / pattern | Why CLI is bypassed |
|----------------|---------------------|
| `.raw/.manifest.json` | Bookkeeping JSON for the raw inbox; not a wiki page. Mutated via `jq + mv` in-place. The CLI has no JSON-mutate verb. |
| `_attachments/images/**` | Binary writes (canvas, defuddle). The CLI has no binary upload verb. |
| Cron-time vault writes | Obsidian is closed; CLI is unreachable. See §5 and #52. |
| `bin/setup-vault.sh`, `bin/seed-demo.sh` | Bootstrap scripts that run before vault registration. The vault is not yet addressable by the CLI. |

---

## 7. Re-spiking after a CLI version bump

After any Obsidian minor-version upgrade, re-run `scripts/cli-spike.sh` and diff `tests/spike-results/` against the committed baseline. Update this file if:

- A new error pattern appears in stdout.
- A verb previously without `format=json` support gains it (update §3 table).
- Exit-code behavior changes.
- A new verb becomes relevant to an existing skill.
