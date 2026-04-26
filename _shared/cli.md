# Obsidian CLI Contract

Every claude-obsidian skill talks to the vault through `scripts/obsidian-cli.sh`. The wrapper resolves the vault, normalizes exit codes, and presents a consistent contract over the upstream `obsidian` CLI. Skills should not invoke `obsidian` directly — call the wrapper instead.

These pages document the wrapper's behavior. Findings are empirical: every claim is backed by a captured run in `tests/spike-results/`. The spike is rerun whenever the upstream CLI moves a major version.

---

## Invocation Contract

The wrapper takes the same verb + args you would pass to `obsidian`, plus its own vault resolution:

```bash
scripts/obsidian-cli.sh <verb> [arg=value ...]
```

A PreToolUse Bash hook (`hooks/obsidian-cli-rewrite.sh`, RTK-style) transparently rewrites raw `obsidian <verb> ...` Bash calls into the wrapper form before they execute. So even if a skill (or a contributor in a fresh terminal) types `obsidian read path=...`, the actual command Bash runs is `"${CLAUDE_PLUGIN_ROOT}/scripts/obsidian-cli.sh" read path=...`. The rewrite is conservative: it only triggers when the **first token** of the command is exactly `obsidian` (so `which obsidian`, `pgrep obsidian`, `cat $obsidian_path` are untouched), and skips commands that already mention `obsidian-cli`.

The wrapper:

1. Calls `scripts/resolve-vault.sh` to get the vault path (`$VAULT`).
2. Derives the vault **name** via `basename "$VAULT"` and prepends `vault=<name>` to the verb call.
3. Pre-flights `obsidian version` once per session (cached) — exits non-zero if the binary is missing or Obsidian is not running.
4. Hard-fails post-vault-resolution: any error from the underlying CLI propagates as a non-zero wrapper exit.

Vault-resolution failure preserves the existing `|| exit 0` fail-soft pattern. Hooks that source `resolve-vault.sh` keep working when no vault is configured.

The CLI's `vault=<name>` parameter is **name-only**. Passing a path (`vault=/tmp/foo`) returns `Vault not found.` to stdout with exit 0. The wrapper always passes the basename of `$VAULT` so callers never have to think about it.

---

## Exit-Code Table

The upstream `obsidian` CLI **always returns exit 0**, regardless of success or failure (verified for ~20 verbs across 30+ cases — see `tests/spike-results/`). The wrapper inspects stdout to detect errors and emits a normalized exit code.

| Wrapper exit | Meaning | Detection |
|---|---|---|
| `0` | Success | stdout does not start with `Error:` or `Vault not found.` |
| `1` | Generic CLI error | stdout starts with `Error:` (e.g. file missing, malformed args, unknown verb, unknown command id) |
| `2` | Vault not found | stdout literal first line `Vault not found.` |
| `3` | Pre-flight failed | `obsidian version` returned non-zero exit, was missing, or had no output (binary missing, Obsidian not running, or version too old) |
| `4` | Vault resolution failed | `resolve-vault.sh` exited non-zero; surfaced only by callers that opted out of fail-soft |

Notes:

- The wrapper preserves stdout/stderr from the underlying CLI verbatim — the exit code is the only normalization on the output channel.
- Callers that historically pipe `|| exit 0` for fail-soft hook behavior continue to work; the wrapper's non-zero exits surface only when callers care.

---

## Format Defaults

Where the upstream CLI supports `format=`, the wrapper does **not** rewrite arguments — callers must opt into JSON explicitly. Skills consuming structured output should pass `format=json` themselves.

| Verb | Has `format=`? | Upstream default | Skills should request |
|---|---|---|---|
| `backlinks` | json\|tsv\|csv | `tsv` | `format=json` |
| `tags` | json\|tsv\|csv | `tsv` | `format=json` |
| `unresolved` | json\|tsv\|csv | `tsv` | `format=json` |
| `outline` | tree\|md\|json | `tree` | `format=json` |
| `search` | text\|json | `text` | `format=json` for structured consumers; `text` for grep-style |
| `bookmarks` | json\|tsv\|csv | `tsv` | `format=json` |
| `aliases` | _(no format)_ | text | text — no JSON option |
| `orphans` | _(no format)_ | text (one path per line) | text — no JSON option |
| `deadends` | _(no format)_ | text (one path per line) | text — no JSON option |
| `tasks` | _(no format)_ | text | text — no JSON option |
| `properties` | _(no format)_ | text | text — no JSON option |
| `read` | _(no format)_ | raw file body | raw |

Empirical correction vs. the original epic plan: `orphans`, `deadends`, `tasks`, and `properties` do **not** accept `format=json`. Skills consuming these verbs parse newline-delimited text. The wrapper does not synthesize JSON for verbs the CLI does not natively format.

`read` and `search format=text` return raw text bodies. Treat them as opaque strings; do not assume JSON.

---

## Error Patterns

The CLI surfaces errors through stdout, in a small set of stable patterns:

| Pattern (first line of stdout) | Cause | Wrapper exit |
|---|---|---|
| `Error: File "<path>" not found.` | `read`/`append`/`prepend` against missing file | `1` |
| `Error: Command "<verb>" not found. ...` | unknown verb (`obsidian doesnotexist`) | `1` |
| `Error: Command "<id>" not found. Use "commands" to list ...` | bad `command id=...` | `1` |
| `Error: No active file. Use file=<name> or path=<path> ...` | verb that needs a file but got none | `1` |
| `Vault not found.` | `vault=<wrong>` or vault by path | `2` |
| _(empty stdout, exit 0)_ | success with no output (e.g. `command id=app:reload`) | `0` |
| _(non-empty stdout, no `Error:` prefix)_ | success | `0` |

The wrapper does not parse beyond the first line — it pattern-matches the literal prefixes above. New error shapes from future CLI versions should be captured in a fresh spike run before being added here.

---

## Escape-Hatch Policy

When the structured CLI cannot express what a skill needs, two escape hatches are available, in increasing risk order:

1. **`command id=<command-id>`** — runs an Obsidian command by ID (the same IDs surfaced in the command palette). Returns empty stdout on success; `Error: Command "..." not found.` on bad ID. Freely allowed where a structured verb does not exist. Use `obsidian commands filter=<prefix>` to discover IDs.

2. **`eval code=<js>`** — last resort. Runs arbitrary JS inside Obsidian's renderer. Every `eval` call must have a per-call comment in the calling skill explaining why no structured verb suffices. Skills should not chain `eval` calls; if more than one is needed, file a follow-up to extend the structured surface.

3. **Direct file ops** — bypassing the CLI entirely (Read/Write/Edit) is reserved for the Documented Exceptions below. Skills that fall back to direct file ops to mask CLI bugs should file the bug, not entrench the workaround.

---

## Documented Exceptions

These callers bypass the wrapper intentionally. Anything not listed here uses the wrapper.

- **`.raw/.manifest.json`** — bookkeeping for the raw inbox; written via Write tool because it is a structured manifest, not a wiki page.
- **Image binaries** (`_attachments/images/**`) — written via Write tool when generating canvas assets; the CLI has no binary-write verb.
- **Cron-time writes when Obsidian is closed** — the cron wrapper writes directly to disk if `obsidian version` pre-flight fails, with a SessionStart reconcile hook to re-index. Documented in `commands/cron.md` (sibling sub-issue, not in scope here).
- **Bootstrap before vault registration** — `bin/setup-vault.sh` and `bin/seed-demo.sh` operate on a vault path before Obsidian has registered it; they cannot use the CLI.
- **Hot-cache fallback** — if a future spike reveals multiline `\n` round-tripping is broken on a CLI version, `save` may fall back to `obsidian create source=/tmp/...` per the upstream `source=` flag. As of CLI 1.12.7 the round-trip is verified intact (see `tests/spike-results/rmw-mutate-diff.out`).

---

## Pinned Empirical Findings (CLI 1.12.7)

Spike run summary — full results in `tests/spike-results/`.

1. **Multiline `\n` round-trips.** `obsidian create content="line one\nline two\nline three"` followed by `obsidian read` returns three distinct lines. No fallback to `source=` needed for hot-cache rewrites.
2. **`vault=<name>` is name-only.** `vault=<path>` returns `Vault not found.` (exit 0). The wrapper resolves to basename.
3. **CLI always exits 0.** Verified across all in-scope verbs and every failure mode tested. Wrapper detects errors via stdout prefix.
4. **`command id=...` returns empty stdout on success**, `Error: Command "..." not found.` on bad ID. Output shape stable.
5. **Cron-time / Obsidian-closed behavior**: not exercised in this spike (Obsidian was running). Cron-wrapper sub-issue runs its own targeted probe and documents the fallback there.
6. **`vault=<name>` against a not-currently-focused but registered vault**: deferred — the spike used the active vault. The wrapper does not assume any specific runtime semantics; if a future skill depends on cross-vault calls, a follow-up spike covers it.

Spike is owned by `scripts/cli-spike.sh`. Re-run after every Obsidian CLI minor version bump; commit the new `tests/spike-results/` and update this file if the contract changes.
