---
name: query
description: "Answer questions using the Obsidian wiki vault. Reads hot cache first, then index, then relevant pages. Synthesizes answers with citations. Files good answers back as wiki pages. Supports quick, standard, and deep modes. Triggers on: what do you know about, query:, what is, explain, summarize, find in wiki, search the wiki, based on the wiki, wiki query quick, wiki query deep."
allowed-tools: Bash Read Glob Grep
---

# query: Query the Wiki

The wiki has already done the synthesis work. Read strategically, answer precisely, and file good answers back so the knowledge compounds.

## Vault I/O

This skill reads `wiki/hot.md`, `wiki/index.md`, and individual pages under `wiki/<category>/`. All reads go through the `obsidian` CLI.

See `${CLAUDE_PLUGIN_ROOT}/_shared/cli.md` for verb syntax, output formats, and exit-code handling.

---

## Query Modes

Three depths. Choose based on the question complexity.

| Mode | Trigger | Reads | Token cost | Best for |
|------|---------|-------|------------|---------|
| **Quick** | `query quick: ...` or simple factual Q | hot.md + index.md only | ~1,500 | "What is X?", date lookups, quick facts |
| **Standard** | default (no flag) | hot.md + index + 3-5 pages | ~3,000 | Most questions |
| **Deep** | `query deep: ...` or "thorough", "comprehensive" | Full wiki + optional web | ~8,000+ | "Compare A vs B across everything", synthesis, gap analysis |

---

## Quick Mode

Use when the answer is likely in the hot cache or index summary.

1. Read `wiki/hot.md`. If it answers the question, respond immediately.
2. If not, read `wiki/index.md`. Scan descriptions for the answer.
3. If found in index summary, respond and do not open any pages.
4. If not found, say "Not in quick cache. Run as standard query?"

Do not open individual wiki pages in quick mode. Do not call `obsidian backlinks` in quick mode — backlink-aware ranking belongs to standard and deep modes; quick mode preserves a ~1.5K token budget.

---

## Standard Query Workflow

A four-step **hybrid retrieval** flow. Stop at the earliest step that answers the question.

1. **Read** `wiki/hot.md` first. It may already have the answer or directly relevant context. If it answers, stop.
2. **Tag-match the question against leaves.** Identify the 1–3 strongest tags or keyword stems from the question. Use `obsidian search query=<term>` (or grep over `wiki/`) to collect candidate clusters of leaves that share those tags. This is faster and narrower than reading `index.md` for most topical questions.
3. **For each cluster, check whether a domain hub exists.** Look for `wiki/domains/<cluster-tag>/_index.md`.
   - **Hub exists** → read the curated hub. The hub's `related:` list is the curated answer set; follow its wikilinks at depth-1 and pull backlinks (`obsidian backlinks path=<leaf> format=json`) on the leaves it links to so heavily cited canonical pages surface in the top-N. This path is preferred — the hub is human-curated and pre-ranked.
   - **No hub** → use the grep-derived tag cluster as the answer set, ranked by backlink count (`obsidian backlinks path=<leaf> format=json`; entries field count = inbound citations). A heavily cited atomic note must surface in the top-N even if its outbound `related:` is sparse.
4. **Fall back to `wiki/index.md`** only when steps 1–3 fail (no hot-cache hit, no tag cluster, no hub). Scan section headers; identify candidate pages; rank by backlinks as in step 3.

After candidates are read:

5. **Step leaf → hub when broader topic context is needed.** If a candidate page is a leaf and the answer needs the wider topic, run `obsidian backlinks path=<leaf> format=json` and read the entries whose frontmatter `type: domain`. That file is the leaf's containing hub. Hub membership is forward-only (hubs link to leaves; leaves never declare membership), so backlinks of `type: domain` are the canonical leaf→hub traversal. Below the hub threshold no hub exists — that is expected, not a gap.
6. **Step synthesis → trail when reading order matters.** If a candidate page has `type: synthesis` (a `Research: [Topic]` page produced by `/autoresearch`), check for a trail: run `obsidian backlinks path=<synthesis> format=json` and filter the entries to those whose frontmatter `type: trail`. The trail is the curated reading order for that research run, with one-line annotations explaining each step's argument role — much cheaper than reconstructing the path from `related:` traversal. See **Trail Discovery** below for the multi-trail rule.
7. **Read** the candidate pages. Follow wikilinks to depth-2 for key entities. No deeper.
8. **Synthesize** the answer in chat. Cite sources with wikilinks: `(Source: [[Page Name]])`.
9. **Offer to file** the answer: "This analysis seems worth keeping. Should I save it as `wiki/questions/answer-name.md`?"
10. If the question reveals a **gap**: say "I don't have enough on X. Want to find a source?"

---

## Deep Mode

Use for synthesis questions, comparisons, or "tell me everything about X."

1. Read `wiki/hot.md` and `wiki/index.md`.
2. **Read every relevant domain hub.** List `wiki/domains/*/​_index.md`; read each hub whose tag intersects the question. Hubs are the cheapest path to a curated, pre-ranked answer set.
3. Identify all relevant leaves across `concepts/`, `entities/`, `sources/`, `solutions/`, `comparisons/` — both the leaves linked from the hubs and any extra leaves the hubs missed (use `obsidian search` for completeness).
4. **Pull backlinks for every candidate.** Run `obsidian backlinks path=<page> format=json` on each candidate to surface canonical pages with high inbound but sparse outbound `related:`, and to find the `type: domain` hubs and `type: trail` reading orders that backlink each candidate. Read any hubs not already covered in step 2. For trails, follow the multi-trail rule in **Trail Discovery** below.
5. Read every relevant page. No skipping.
6. If wiki coverage is thin, offer to supplement with web search.
7. Synthesize a comprehensive answer with full citations.
8. Always file the result back as a wiki page. Deep answers are too valuable to lose.

---

## Token Discipline

Read the minimum needed:

| Start with | Cost (approx) | When to stop |
|------------|---------------|--------------|
| hot.md | ~500 tokens | If it has the answer |
| index.md | ~1000 tokens | If you can identify 3-5 relevant pages |
| 3-5 wiki pages | ~300 tokens each | Usually sufficient |
| 10+ wiki pages | expensive | Only for synthesis across the entire wiki |

If hot.md has the answer, respond without reading further.

For the full hot-cache protocol (when it is written, what it contains, and sub-agent rules), see `${CLAUDE_PLUGIN_ROOT}/_shared/hot-cache-protocol.md`.

---

## Index Format Reference

The master index (`wiki/index.md`) looks like:

```markdown
## Domains
- [[Domain Name]]: description (N sources)

## Entities
- [[Entity Name]]: role (first: [[Source]])

## Concepts
- [[Concept Name]]: definition (status: developing)

## Sources
- [[Source Title]]: author, date, type

## Questions
- [[Question Title]]: answer summary
```

Scan the section headers first to determine which sections to read.

---

## Domain Hub Format

Domain hubs live at `wiki/domains/<slug>/_index.md`. Each hub is the curated entry point for one cluster:

```markdown
---
type: domain
title: "Knowledge Management"
owns_folder: false
subdomain_of: ""
page_count: 12
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags: [domain, knowledge-management]
status: developing
confidence: EXTRACTED
evidence: []
related:
  - "[[llm-wiki-pattern|LLM Wiki Pattern]]"
  - "[[hot|Hot Cache]]"
  - "[[compounding-knowledge|Compounding Knowledge]]"
---

# Knowledge Management

One-paragraph hub description.

## Core concepts
- [[llm-wiki-pattern|LLM Wiki Pattern]] — one-line description
- [[compounding-knowledge|Compounding Knowledge]] — one-line description

## Sources
- [[llm-wiki-karpathy-gist|Karpathy's LLM Wiki Gist]] — origin source
```

Reach a hub via step 3 of the standard flow (`wiki/domains/<cluster-tag>/_index.md`) or via the leaf→hub backlink traversal in step 5.

Per-folder `<folder>/_index.md` files are not used. Folders like `concepts/`, `entities/`, `sources/`, `solutions/` are flat directories; cross-folder navigation goes through hubs.

---

## Trail Discovery

Trails are run-records emitted by `/autoresearch`. They live under `wiki/trails/Trail: [Topic] (YYYY-MM-DD).md` and answer "in what order, and why each next?" — complementary to hubs ("what notes are about X?"). When the question is about a topic that has been research-ran, the trail is usually the cheapest route to the right reading order.

**Discovery procedure** (synthesis → trail):

1. When a candidate page has `type: synthesis` (e.g. `Research: [Topic]`), run:
   ```bash
   obsidian backlinks path=<synthesis-path> format=json
   ```
2. Filter the returned entries to those whose frontmatter `type: trail`. (Read the candidate's frontmatter via `obsidian read path=<entry>` if the JSON does not already include it.) These are the trails covering that research run.
3. **Multi-trail rule.** If more than one trail backlinks the synthesis (multiple runs on the same topic), pick the **most recent** by the `YYYY-MM-DD` date suffix on the filename — the date suffix is canonical, not the `research_run:` field, because filename ordering is what the index/log entries point at. Read only that trail. After answering, append exactly:
   ```
   *N earlier trail(s) exist on this topic — say 'compare trails' to read all.*
   ```
   where N is the count of older trails. Skip the line entirely when only one trail exists.
4. **`compare trails` follow-up.** If the user replies with "compare trails" (or equivalent), read all trails for the topic, oldest first, and synthesize an evolution view — what changed between runs, what stayed, what dropped out.

**Trail vs. hub** — both are reachable via backlinks, but they answer different questions and the discovery filter (`type: trail` vs. `type: domain`) is the disambiguator. A page can have both kinds of backlinks; read the trail when the user is re-entering a research topic, the hub when the user is exploring a domain.

**Fallback.** If no trail exists for a synthesis page, fall back to the existing backlink/hub traversal in steps 5–6 of the standard flow. No trail is not a gap — older research runs predate this feature, and a thin run may have produced no trail at all.

---

## Filing Answers Back

Good answers compound into the wiki. Don't let insights disappear into chat history.

When filing an answer:

```yaml
---
type: question
title: "Short descriptive title"
question: "The exact query as asked."
answer_quality: solid
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags: [question, <domain>]
related:
  - "[[Page referenced in answer]]"
sources:
  - "[[wiki/sources/relevant-source.md]]"
status: developing
---
```

Then write the answer as the page body. Include citations. Link every mentioned concept or entity.

After filing, add an entry to `wiki/index.md` under Questions and append to `wiki/log.md`.

---

## Gap Handling

If the question cannot be answered from the wiki:

1. Say clearly: "I don't have enough in the wiki to answer this well."
2. Identify the specific gap: "I have nothing on [subtopic]."
3. Suggest: "Want to find a source on this? I can help you search or process one."
4. Do not fabricate. Do not answer from training data if the question is about the specific domain in this wiki.
