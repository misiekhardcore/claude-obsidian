# CLI Contract

Reference for the Obsidian CLI. All behaviors verified by `scripts/cli-spike.sh` (results in `tests/spike-results/`).

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
|`create-or-append`|wrapper-only; see §3.1|

**Multiline `content=`:** `\n` and `\t` round-trip correctly. Use `\n` for newlines.

**`content=` escape asymmetry:** `\\` does NOT produce literal backslash — every `\n` becomes newline regardless. For canvas JSON or code blocks with literal backslashes, use `eval` escape hatch:

```bash
obsidian eval code="await app.vault.adapter.write('path/to/file', '<full content>');"
```

### 3.1 `create-or-append` (wrapper-only)

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

Does NOT read body or touch frontmatter. Use `property:set` (§3.2) for `updated:` mutations.

### 3.2 Native property verbs

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

Intentional CLI bypasses (verify call sites before removing):

|Path|Why|
|-|-|
|`.raw/.manifest.json`|JSON mutation via `jq + mv`; no CLI JSON verb|
|`_attachments/images/**`|Binary writes; no CLI binary verb|
|Cron writes|Obsidian closed; unreachable (§5)|
|`bin/setup-vault.sh`, `bin/seed-demo.sh`|Bootstrap before vault registration|

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
