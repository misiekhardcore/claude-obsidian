# Authoring Guide

Conventions for adding skills and shared protocols to this plugin.

---

## Directory Layout

```text
_shared/          Cross-skill reference docs — read on demand by any skill that needs them
scripts/          Utility scripts
  obsidian-cli.sh Wrapper for the Obsidian CLI (canonical vault-touch primitive)
  resolve-vault.sh Vault path resolution logic
skills/<name>/    One directory per skill
  SKILL.md        The skill entrypoint — loaded when the skill is invoked
  references/     Skill-local reference docs, not needed by other skills
agents/           Sub-agent definitions (dispatched by orchestrating skills)
commands/         Slash-command shims that load a skill
hooks/            Claude Code hooks (hooks.json + shell scripts)
_templates/       This directory — authoring guidance and Obsidian Templater templates
```

---

## When to use `_shared/`

Promote a document to `_shared/` only when **three or more skills** need to read it. If only one or two skills reference a doc, keep it under `skills/<name>/references/`.

Current shared docs:

- `_shared/vault-structure.md` — vault directory map, confidence tagging semantics, typed-relationship semantics
- `_shared/frontmatter.md` — universal YAML field schema, status/confidence values, typed relationship YAML shape
- `_shared/hot-cache-protocol.md` — when to read/write `wiki/hot.md` and what to put in it
- `_shared/cli.md` — empirical Obsidian CLI contract (exit codes, error patterns, escape hatches)

---

## Vault Operations: CLI Wrapper

All vault reads and writes must go through `scripts/obsidian-cli.sh`, the canonical vault-touch primitive. The wrapper resolves the vault, pre-flights the Obsidian connection, and normalizes exit codes.

```bash
# Read a file
"${CLAUDE_PLUGIN_ROOT}/scripts/obsidian-cli.sh" read path=wiki/hot.md

# Create a file
"${CLAUDE_PLUGIN_ROOT}/scripts/obsidian-cli.sh" create path=wiki/concepts/foo.md content="..."

# Append to a file
"${CLAUDE_PLUGIN_ROOT}/scripts/obsidian-cli.sh" append path=wiki/index.md content="- New entry"
```

A PreToolUse Bash hook (`hooks/obsidian-cli-rewrite.sh`) transparently rewrites raw `obsidian <verb> ...` invocations to the wrapper, but skills should call the wrapper explicitly for clarity.

For error handling, exit-code semantics, and escape hatches (commands, eval), see `${CLAUDE_PLUGIN_ROOT}/_shared/cli.md`.

---

## How skills reference `_shared/` files

Use `${CLAUDE_PLUGIN_ROOT}/_shared/<file>` in skill prose and instructions. This is a runtime path that Claude Code resolves at load time. Do not hardcode absolute paths.

```markdown
See `${CLAUDE_PLUGIN_ROOT}/_shared/vault-structure.md` for the directory map.
```

Skills should read `_shared/` files on demand, not preload them at skill start.

---

## Promotion rubric

Promote a `skills/<name>/references/` document to `_shared/` when:

1. Three or more skills reference the same content
2. The content is genuinely cross-cutting (not specific to one skill's operation)
3. Duplication across skills would create a maintenance risk

Do not promote docs that describe a single skill's internal procedure, even if they are long or detailed.
