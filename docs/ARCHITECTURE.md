# Architecture — Personal Memory Assistant

## Context

Hermes Agent has two built-in persistence mechanisms:

- **Memory tool:** Durable key-value store, injected into every system prompt. Fast but space-limited (~2,200 chars).
- **Session transcripts:** Full conversation logs in `~/.hermes/sessions/`. Searchable but subject to pruning; not designed for 10-year retention.

Neither alone is sufficient for a lifetime personal memory system. This project adds a third layer — a durable, structured journal on disk — and defines how all three layers collaborate.

## Goals

- Unlimited storage of personal notes, events, and facts
- Retrieval within seconds across thousands of entries
- Survives Hermes reinstalls, profile swaps, and machine changes
- Accessible both through the assistant and directly (grep, editor, scripts)
- Works across all Hermes platforms (CLI, Telegram, Discord, etc.)

## Non-Goals

- Low-latency real-time sync across devices (manual backup is fine)
- Semantic/vector search (plain-text search is sufficient for v1)
- Multimedia storage
- Multi-user collaboration

## Architecture Overview

```
┌──────────────────────────────────────────────────────────────────┐
│                     HERMES AGENT (AI Layer)                      │
│                                                                  │
│  ┌──────────┐  ┌──────────────┐  ┌──────────────────────────┐   │
│  │ memory   │  │ session_     │  │ terminal / write_file /  │   │
│  │ tool     │  │ search tool  │  │ read_file                │   │
│  └────┬─────┘  └──────┬───────┘  └────────────┬─────────────┘   │
│       │               │                        │                 │
└───────┼───────────────┼────────────────────────┼─────────────────┘
        │               │                        │
        ▼               ▼                        ▼
┌───────────────┐ ┌──────────────┐ ┌──────────────────────────┐
│  Layer 1      │ │  Layer 2     │ │  Layer 3 (THIS PROJECT)  │
│  Memory       │ │  Session     │ │  Durable Journal         │
│  (~2K chars)  │ │  Transcripts │ │  ~/journal/YYYY/MM-DD*   │
│  Fast facts   │ │  Recent      │ │  Unlimited, searchable   │
│  Always on    │ │  convos      │ │  Portable markdown       │
└───────────────┘ └──────────────┘ └──────────────────────────┘
```

## Three-Layer Memory Model

### Layer 1: Memory (Hermes built-in)

**Purpose:** High-speed recall of stable facts
**Contents:** Your name, profession, key relationships, recurring preferences, important dates
**Limits:** ~2,200 chars total; injected into every turn
**Management:** Updated via `memory` tool when facts change

### Layer 2: Session Transcripts (Hermes built-in)

**Purpose:** Short-to-medium term conversation recall
**Contents:** Raw chat logs
**Limits:** Subject to `hermes sessions prune`; not designed for permanent retention
**Management:** Accessed via `session_search` tool

### Layer 3: Durable Journal (THIS PROJECT)

**Purpose:** Permanent, unlimited storage of everything worth remembering
**Contents:** Daily journal entries, events, ideas, decisions, notes
**Format:** Plain markdown, date-indexed
**Limits:** No hard limit (filesystem-dependent)
**Management:** Created/read by Hermes via `write_file`/`read_file`; also directly accessible

## Data Flow

### Recording

```
User: "Remember that I finished the Q2 review today"
         │
         ▼
Hermes Agent analyzes intent
         │
         ├──► If stable fact:         memory tool (add)
         │
         └──► If journal-worthy:      write_file → journal/2026/04-28-q2-review.md
                                              │
                                              └──► memory tool: note that entry exists
```

### Retrieval

```
User: "What happened in Q2 this year?"
         │
         ▼
Hermes Agent decides search strategy
         │
         ├──► If specific fact:       memory tool (recall)
         │
         ├──► If recent conversation:  session_search
         │
         └──► If historical journal:   read_file + grep → journal/2026/
                                              │
                                              └──► Synthesize + summarize response
```

## Journal Entry Schema

```markdown
# YYYY-MM-DD: Descriptive Title

## Tags
tag1, tag2, tag3

## Summary
One or two sentences.

## Details
Free-form markdown content.
Can include lists, code blocks, links, etc.

## People
- Name — context (e.g., "Alice — met at conference, works on ML")

## Linked
- [[YYYY-MM-DD-related-entry]]
- External links or references
```

## Scripts

| Script | Purpose |
|---|---|
| `new-entry.sh` | Creates a dated entry with template, opens in editor |
| `search.sh` | Full-text search across all journal entries |
| `monthly-digest.sh` | Aggregates all entries for a given month into a summary |
| `backup.sh` | Archives the journal directory |

## Directory Layout

```
personal-memory-assistant/
├── README.md
├── docs/
│   ├── PRD.md
│   ├── ARCHITECTURE.md          ← you are here
│   ├── TECH-STACK.md
│   ├── ROADMAP.md
│   ├── CHANGELOG.md
│   ├── VALIDATION.md
│   └── decisions/
│       └── 001-*.md
├── config/
│   ├── .env.example
│   └── journal.yaml
├── scripts/
│   ├── new-entry.sh
│   ├── search.sh
│   ├── monthly-digest.sh
│   └── backup.sh
├── journal/
│   └── YYYY/
│       └── MM-DD-title.md
├── .gitignore
└── LICENSE
```
