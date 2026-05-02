---
type: meta
title: "Getting Started"
created: 2026-05-02
updated: 2026-05-02
tags:
  - meta
  - onboarding
status: evergreen
related:
  - "[[index]]"
  - "[[hot]]"
---

# Getting Started with claude-obsidian

Welcome. This vault is your compounding knowledge base — a persistent second brain built with Claude and Obsidian.

Every source you add gets processed into 8–15 cross-referenced wiki pages. Every question you ask pulls from everything that's been ingested. Knowledge compounds like interest.

---

## How it works — data flow

```mermaid
%%{init: {'theme':'base', 'themeVariables': {'background':'#000','primaryColor':'#ffffff','primaryTextColor':'#000000','primaryBorderColor':'#000000','lineColor':'#000000','textColor':'#000000','titleColor':'#000000','clusterBkg':'#f3f4f6','clusterBorder':'#000000','edgeLabelBackground':'#ffffff'}}}%%
flowchart TB
    You([You])

    subgraph Capture["Capture surfaces"]
        direction LR
        C_Drop[".raw/ drop<br/>files · URLs · images"]
        C_Note["/note · /dump"]
        C_Daily["/daily"]
        C_Brain["/braindump"]
        C_Save["/save<br/>(this conversation)"]
    end

    You --> C_Drop
    You --> C_Note
    You --> C_Daily
    You --> C_Brain
    You --> C_Save

    subgraph Inboxes["Inboxes — verbatim stores"]
        direction LR
        S_Raw[(".raw/")]
        S_Notes[("notes/")]
        S_Daily[("daily/")]
    end

    C_Drop --> S_Raw
    C_Note --> S_Notes
    C_Daily --> S_Daily

    subgraph Processing["Processing — make wiki pages"]
        direction LR
        P_Ingest["/ingest"]
        P_NoteProc["/note process"]
        P_DailyClose["/daily-close"]
        P_Auto["/autoresearch"]
    end

    S_Raw --> P_Ingest
    S_Notes --> P_NoteProc
    S_Daily --> P_DailyClose
    C_Brain --> P_Ingest
    C_Save --> P_Ingest
    P_Auto --> S_Raw

    subgraph Wiki["wiki/ — compounding knowledge"]
        direction TB
        W_Hot[("hot.md<br/>recent context")]
        W_Index[("index.md<br/>master catalog")]
        W_Log[("log.md<br/>operations log")]
        W_Concepts["concepts/<br/>ideas & frameworks"]
        W_Entities["entities/<br/>people · orgs · tools"]
        W_Sources["sources/<br/>summaries"]
        W_Domains["domains/<br/>topic hubs"]
        W_Questions["questions/<br/>open & answered"]
        W_Meta["meta/<br/>dashboards · reports"]
    end

    P_Ingest --> W_Concepts
    P_Ingest --> W_Entities
    P_Ingest --> W_Sources
    P_NoteProc --> W_Concepts
    P_DailyClose --> W_Sources
    P_Ingest -. updates .-> W_Index
    P_Ingest -. updates .-> W_Log
    P_Ingest -. updates .-> W_Hot

    subgraph Retrieve["Retrieve — read the vault"]
        direction LR
        R_Query["query · ask Claude"]
        R_Boot["session start<br/>(hot auto-load)"]
    end

    W_Hot -. auto-injected .-> R_Boot
    W_Index --> R_Query
    W_Concepts --> R_Query
    W_Entities --> R_Query
    W_Sources --> R_Query
    W_Domains --> R_Query
    R_Query --> You
    R_Boot --> You

    subgraph Maintain["Maintenance"]
        direction LR
        M_Lint["wiki-lint<br/>orphans · dead links"]
        M_Canvas["/canvas<br/>visual graph"]
    end

    W_Concepts -. weekly cron .-> M_Lint
    M_Lint -. auto-fix .-> Wiki
    Wiki --> M_Canvas

    classDef orch fill:#dddddd,stroke:#000000,stroke-width:2px,color:#000000
    classDef spec fill:#eeeeee,stroke:#000000,stroke-width:2px,color:#000000
    classDef store fill:#a5b4fc,stroke:#000000,stroke-width:2px,color:#000000
    classDef you fill:#fde68a,stroke:#000000,stroke-width:2px,color:#000000
    class Capture,Inboxes,Processing,Wiki,Retrieve,Maintain orch
    class C_Drop,C_Note,C_Daily,C_Brain,C_Save spec
    class P_Ingest,P_NoteProc,P_DailyClose,P_Auto spec
    class W_Concepts,W_Entities,W_Sources,W_Domains,W_Questions,W_Meta spec
    class R_Query,R_Boot,M_Lint,M_Canvas spec
    class S_Raw,S_Notes,S_Daily,W_Hot,W_Index,W_Log store
    class You you
```

**Reading the diagram**: you (yellow) interact through capture surfaces (light gray) that land in verbatim inboxes (indigo). Processing skills turn inboxes into structured wiki pages. The wiki feeds retrieval — both explicit queries and the auto-loaded hot cache at session start. Maintenance runs on a cadence (manual or cron) and writes back into the wiki.

---

## Three-Step Quick Start

### 1. Drop a source

Put any document into the `.raw/` folder:
- PDFs, markdown files, transcripts, articles
- Or paste a URL and ask Claude to fetch it

### 2. Ingest it

Tell Claude in any Claude Code session:

```
ingest [filename]
```

Claude reads the source, creates 8–15 wiki pages under `wiki/`, cross-references everything, and updates `wiki/index.md`, `wiki/log.md`, and `wiki/hot.md`.

### 3. Ask questions

```
what do you know about [topic]?
```

Claude reads the hot cache, scans the index, drills into relevant pages, and gives you a synthesized answer — citing specific wiki pages, not training data.

---

## How the Hot Cache Works

`wiki/hot.md` is a ~500-word summary of recent vault context. It loads automatically at the start of every session (via the SessionStart hook).

You don't need to recap. Claude starts every session knowing what you've been working on.

Update it manually at any time: `update hot cache`

---

## Your First Ingest — Walkthrough

1. Create a file in `.raw/` — copy a transcript, paste an article, or save a PDF
2. Open Claude Code in this vault folder
3. Type: `ingest [your-filename]`
4. Watch the wiki grow — Claude will report which pages it created
5. Open `wiki/index.md` — you'll see the new pages listed
6. Open Graph View in Obsidian — a new cluster of connected nodes appears

After 3–5 ingests, the graph starts to look like a real knowledge network. Cross-references emerge automatically.

---

## Key Commands

| You say | Claude does |
|---------|-------------|
| `ingest [file]` | Creates 8–15 wiki pages from a source |
| `what do you know about X?` | Queries the wiki, cites pages |
| `/save` | Files this conversation as a wiki note |
| `/autoresearch [topic]` | Searches the web, ingests results autonomously |
| `lint the wiki` | Health check — finds orphans, gaps, stale links |
| `update hot cache` | Refreshes the session context summary |

---

## Next Steps

- Open **[[index]]** for the master catalog of every page in your vault.
- Read **[[hot]]** to see what context Claude is currently carrying into sessions.
- Drop your first source into `.raw/` and run an ingest.

---

*Built on the LLM Wiki pattern by Andrej Karpathy: https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f*
