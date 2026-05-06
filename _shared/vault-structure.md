# Vault Structure

Cross-skill structural conventions for the claude-obsidian vault: directory layout, page types, confidence tagging semantics, and typed-relationship semantics.

Read this file when a skill needs to understand vault layout or interpret page metadata. Do not preload — read on demand.

---

## Directory Map

| Directory           | Type value   | What goes here                                                                                                                                                             | Naming convention                                                                         |
| ------------------- | ------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| `wiki/concepts/`    | `concept`    | Patterns, techniques, ideas, how-things-work explanations                                                                                                                  | Title Case or kebab-case slug; no "the" prefix                                            |
| `wiki/entities/`    | `entity`     | Named real-world things: people, tools, products, orgs, repos                                                                                                              | Proper noun as named in the source                                                        |
| `wiki/sources/`     | `source`     | One page per ingested source — metadata, key findings, links to derived pages                                                                                              | `<slug>` matching the `.raw/` filename                                                    |
| `wiki/solutions/`   | `solution`   | Concrete recipes: how to accomplish a specific task end-to-end                                                                                                             | Verb phrase, e.g. `register-vault-with-cli`                                               |
| `wiki/comparisons/` | `comparison` | Side-by-side analysis of 2+ alternatives                                                                                                                                   | `<A>-vs-<B>` or `comparing-<topic>`                                                       |
| `wiki/questions/`   | `question`   | Open questions; closed questions link to the answer                                                                                                                        | Question as written, e.g. `why-tokens-compound`                                           |
| `wiki/domains/`     | `domain`     | Universal hub root for domain hubs; each hub is `wiki/domains/<slug>/_index.md`                                                                                            | kebab-case slug, e.g. `machine-learning`, `sophia`                                        |
| `wiki/trails/`      | `trail`      | One reading-order record per `/autoresearch` run — lists atomic notes in argument order with one-line annotations. Created lazily on first run; never edited post-emission | `Trail: [Topic] (YYYY-MM-DD)` — date suffix distinguishes multiple runs on the same topic |
| `wiki/meta/`        | `meta`       | Index files, log, hot cache, dashboards — structural pages                                                                                                                 | Short functional names: `index`, `log`, `hot`                                             |

**Examples:**

- `wiki/concepts/LLM Wiki Pattern.md` — a technique (concept)
- `wiki/entities/Andrej Karpathy.md` — a person (entity)
- `wiki/sources/llm-wiki-karpathy-gist.md` — the ingest record for a specific source
- `wiki/solutions/register-vault-with-cli.md` — step-by-step recipe (solution)
- `wiki/domains/knowledge-management/_index.md` — a domain hub curating concepts/entities/sources across folders

> Per-folder `<folder>/_index.md` files are **not** part of this layout. Curation lives only in `wiki/domains/<slug>/_index.md`. Folders like `concepts/`, `entities/`, `solutions/`, `sources/` are flat directories of leaves; navigation crosses them via domain hubs and backlinks.

---

## Hub Membership

Domain hubs link to leaves; **leaves do not declare hub membership**. There is no `domain:` field on a leaf. To resolve a leaf to its containing hub, the agent runs `obsidian backlinks path=<leaf> format=json` and filters the result for entries whose frontmatter has `type: domain`.

| Direction  | How it is encoded                                                                                |
| ---------- | ------------------------------------------------------------------------------------------------ |
| Hub → leaf | `related:` wikilink in `wiki/domains/<slug>/_index.md` (forward link)                            |
| Leaf → hub | Backlink resolution (`obsidian backlinks` filtered by `type: domain`); never a frontmatter field |

This forward-only model keeps hub membership in one file per cluster (the hub itself), avoids the dual-write problem, and lets a leaf belong to multiple hubs without per-leaf frontmatter churn.

Below the threshold for a hub (≈10 leaves), no hub exists; queries fall back to grep + tags + backlinks. See `${CLAUDE_PLUGIN_ROOT}/skills/lint/SKILL.md` for the hub promotion / demotion thresholds.

---

## Confidence Tagging

Every page carries a `confidence:` field with one of three values:

| Value       | Meaning                                 | When to use                                                   |
| ----------- | --------------------------------------- | ------------------------------------------------------------- |
| `EXTRACTED` | Claims sourced directly from a document | Source pages; entity/concept claims that are literally quoted |
| `INFERRED`  | Claims derived by the LLM from sources  | Most concept and entity pages                                 |
| `AMBIGUOUS` | Conflicting signals; needs human review | Pages where sources contradict and resolution is unclear      |

`AMBIGUOUS` pages must also list the open conflict in the `open_questions` field or in a `## Perspectives` section.

The `evidence:` field is a flat list of source wikilinks supporting the page's claims. Required for `INFERRED` and `AMBIGUOUS` pages.

**Default assignments by page type:**

- `source` pages → `EXTRACTED` (the page summarises what was directly found in the document)
- `concept` pages → `INFERRED` (LLM synthesis from one or more sources)
- `entity` pages → `INFERRED` (unless the entity's details are verbatim-quoted)
- `meta` pages (index, log, hot) → `EXTRACTED` (mechanically generated, not inferred)
- `trail` pages → `EXTRACTED` (records what the autoresearch run produced; no inference)

---

## Typed Relationships

Alongside `related:`, use typed fields when the semantic is unambiguous:

| Field          | Meaning                                                         |
| -------------- | --------------------------------------------------------------- |
| `supersedes:`  | This page replaces the listed page(s)                           |
| `contradicts:` | This page's claims conflict with the listed page(s)             |
| `uses:`        | This page/concept applies or depends on the listed page(s)      |
| `depends_on:`  | Stronger dependency — can't function without the listed page(s) |
| `caused:`      | This page describes something that caused the listed outcome(s) |
| `fixed:`       | This page describes a fix for the listed issue(s)               |
| `implements:`  | This page is an implementation of the listed spec/pattern(s)    |

All typed relationship fields are optional flat lists. Keep `related:` for general or untyped links. Add typed fields only when the semantic is genuinely unambiguous.

For the YAML shape of these fields, see `${CLAUDE_PLUGIN_ROOT}/_shared/frontmatter.md` §Typed Relationship Fields.
