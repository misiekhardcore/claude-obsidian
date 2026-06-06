# CLI Contract

**Scope.** Authoritative reference for the Obsidian CLI mechanics: invocation, full verb table with output formats, exit codes, `content=` escape rules, canvas handling, and the re-spike procedure. All behaviors verified by `scripts/cli-spike.sh` (results in `tests/spike-results/`).

For skill-author operational patterns (when/why to call each verb, slugging, indexing, hot-cache protocol, active enforcement, canonical bypass list) see `${CLAUDE_PLUGIN_ROOT}/_shared/vault-ops.md`.

Read on demand.

## 1. Invocation contract

All vault operations through `scripts/obsidian-cli.sh` (PreToolUse hook rewrites bare `obsidian` calls transparently).

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/obsidian-cli.sh" read path=wiki/hot.md
```

**vault= is name-only** (basename, not path). Wrapper derives it automatically.

**Obsidian must be running.** CLI is desktop IPC; SessionStart hook probes connectivity.

**All output to stdout** (including errors). Wrapper normalizes exit codes.

## 2. Exit codes

See `${CLAUDE_PLUGIN_ROOT}/_shared/cli-reference.md` for full exit-code table and escape hatches.

## 3. Format defaults

Locked by empirical spike. Do not override without documented reason.

|Verb|Output format|
|-|-|
|`read`|plain text|
|`create`|`Created: <path>`|
|`append`|`Appended to: <path>`|
|`prepend`|`Prepended to: <path>`|
|`backlinks`|json: `[{"file": "<path>"}]`|
|`unresolved`|json: `[{"link": "..."}]`|
|`search`|json|
|`search:context`|plain text|
|`orphans`|plain text (no json support)|
|`deadends`|plain text (no json support)|
|`tasks`|plain text (no json support)|
|`tags`|plain text (no json support)|
|`properties`|plain text (no json support)|
|`property:read`|plain text (single value)|
|`property:set`|plain text|
|`property:remove`|plain text|
|`bases`|plain text|
|`commands`|plain text|
|`outline`|plain text|
|`read-head`|wrapper-only; see §3.1|
|`grep`|wrapper-only; see §3.1|
|`grep-files`|wrapper-only; see §3.1|
|`create-or-append`|wrapper-only; see §3.1|

**Multiline `content=`:** `\n` and `\t` round-trip correctly. Use `\n` for newlines.

**`content=` escape asymmetry:** `\\` does NOT produce literal backslash — every `\n` becomes newline regardless. For canvas JSON or code blocks with literal backslashes, use `eval` escape hatch:

```bash
obsidian eval code="await app.vault.adapter.write('path/to/file', '<full content>');"
```

### 3.1 Context-saving read verbs (wrapper-only)

These verbs return partial file content to save LLM context without sacrificing access to vault information.

#### `read-head`

Read first N lines of a vault file (frontmatter + intro). Default N=20 covers frontmatter plus the first paragraph for most wiki pages — ~200 tokens vs ~1,000+ for a full read.

```bash
obsidian read-head path=wiki/concepts/foo.md
obsidian read-head path=wiki/hot.md lines=10
```

|Aspect|Behavior|
|-|-|
|`path=`|Required. Vault-relative path.|
|`lines=N`|Optional. Positive integer. Default: 20.|
|Output|First N lines of the file (plain text).|
|Exit|0 success; 1 error (bad args, missing file via underlying read).|

#### `grep`

Search within a single vault file. Returns matching lines without loading the full file into LLM context. Uses `obsidian read | grep` underneath.

```bash
obsidian grep path=wiki/hot.md pattern="agent" context=2
obsidian grep path=wiki/index.md pattern="orphan" ignore-case=true
```

|Aspect|Behavior|
|-|-|
|`path=`|Required. Vault-relative path.|
|`pattern=`|Required. Extended regex (grep -E syntax).|
|`context=N`|Optional. Lines of surrounding context. Default: 0.|
|`ignore-case=true`|Optional. Case-insensitive match. Default: false.|
|Output|Matching lines (grep format).|
|Exit|0 matches found; 1 no matches or error.|

#### `grep-files`

Search for a pattern across multiple vault files. Uses filesystem grep directly (read-only, low risk) — much faster than per-file `obsidian read`. Default scope is `wiki/`. Limited to 50 matches to prevent flooding context.

```bash
obsidian grep-files pattern="hot cache" context=1
obsidian grep-files pattern="orchestration" dir=wiki/concepts ignore-case=true
```

|Aspect|Behavior|
|-|-|
|`pattern=`|Required. Extended regex (grep -E syntax).|
|`dir=`|Optional. Vault-relative directory. Default: `wiki`.|
|`context=N`|Optional. Lines of surrounding context. Default: 0.|
|`ignore-case=true`|Optional. Case-insensitive match. Default: false.|
|Output|Matching lines with vault-relative filename prefix.|
|Exit|0 matches found; 1 no matches; 2 bad args (dir not found).|

### 3.2 `create-or-append` (wrapper-only)

Atomic "create or append" (prevents read-modify-overwrite races per issue #98).

```bash
obsidian create-or-append \
  file=daily/YYYY-MM-DD.md \
  template="---\ntype: daily\n...\n---\n\n## Captures\n" \
  content="- HH:MM <verbatim text>"
```

|Aspect|Behavior|
|-|-|
|File missing|Create via template, then append content|
|File exists|Append content only; template ignored|
|`template=`|Required|
|Output (missing)|`Created and appended: <path>`|
|Output (exists)|`Appended to: <path>`|
|Exit|0 success; 1 on error|

Does NOT read body or touch frontmatter. Use `property:set` (§3.3) for `updated:` mutations.

### 3.3 Native property verbs

Read, write, or remove a single frontmatter property without touching the file body.

```bash
# Read one property value
obsidian property:read name=updated path=daily/YYYY-MM-DD.md

# Set (or insert) a property — type= is optional; omit for plain text
obsidian property:set name=updated value=YYYY-MM-DD type=date path=daily/YYYY-MM-DD.md

# Remove a property
obsidian property:remove name=draft path=wiki/concepts/foo.md

# List all properties of a file (yaml output by default)
obsidian properties path=wiki/concepts/foo.md
```

|Verb|Required args|Optional args|
|-|-|-|
|`property:read`|`name=`|`file=` or `path=`|
|`property:set`|`name=`, `value=`|`type=text\|list\|number\|checkbox\|date\|datetime`, `file=` or `path=`|
|`property:remove`|`name=`|`file=` or `path=`|
|`properties`|—|`file=` or `path=`, `name=`, `total`, `sort=count`, `counts`, `format=yaml\|json\|tsv`|

**Re-spike after CLI version bump:** add `property:*` cases to `scripts/cli-spike.sh` and capture results.

## 4. Cron-time behavior

CLI requires Obsidian running; cron context fails at pre-flight (exit 3). See issue #52 for workaround.

## 5. Documented exceptions

For the canonical list of paths where direct `Read` / `Write` / `Edit` on vault files is permitted because the CLI cannot serve the operation, see `vault-ops.md §5`. That list (binary files, canvas, JSON admin artifacts, `.raw/**` reads) is enforced by `hooks/block-direct-vault-io.sh`.

Non-vault exceptions still relevant to the CLI:

|Context|Why|
|-|-|
|Cron writes|Obsidian closed; CLI pre-flight fails (§4). See issue #52.|
|`bin/setup-vault.sh`, `bin/seed-demo.sh`|Bootstrap runs before vault registration; vault path not yet resolvable.|

## 6. Canvas file handling

Canvas files (`.canvas`) lack CLI verbs. Mix standard verbs + direct reads:

|Operation|Approach|
|-|-|
|List|`obsidian files dir=wiki/canvases format=json`|
|Read|Direct FS read (bypass due to `content=` asymmetry)|
|Extract wikilinks|Parse `.nodes[]?.text` for `[[...]]`; `obsidian unresolved` doesn't cover canvas|
|Verify dead links|Build FS resolver pool; test against it (ref: `scripts/lint-scan.sh`)|
|Write|Direct FS write (bypass; `content=` would corrupt literal `\n`)|
|Backlinks|`obsidian backlinks path=wiki/canvases/foo.canvas format=json`|

**`obsidian files` verb:** `obsidian files dir=<dir> format=json` → array of `{"path": "..."}`. Filter extensions client-side with `jq`.

## 7. Re-spiking after CLI version bump

Run `scripts/cli-spike.sh` and diff `tests/spike-results/`. Update this file if:
- New error patterns in stdout
- Verb gains `format=json` support (update §3 table)
- Exit codes change
- New verb relevant to skills
