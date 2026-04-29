# Architecture — Personal Memory Assistant

## Context

Hermes Agent has two built-in persistence mechanisms:

- **Memory tool:** Durable key-value store, injected into every system prompt. Fast but space-limited (~2,200 chars).
- **Session transcripts:** Full conversation logs. Searchable but subject to pruning; not designed for 10-year retention.

Neither alone is sufficient for a lifetime personal memory system. This project adds a third layer — a durable, structured journal on disk — and defines how all three layers collaborate.

## Goals

- Unlimited storage of personal notes, events, and facts
- Retrieval within seconds across thousands of entries
- Survives Hermes reinstalls, profile swaps, and machine changes
- Accessible both through the assistant and directly (grep, editor, scripts)
- Works across all Hermes platforms (CLI, Telegram, Discord, etc.)

## Non-Goals

- Low-latency real-time sync across devices (daily cron + git push is sufficient)
- Semantic/vector search (grep + scripts is sufficient for v1)
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
│       │    Skills     │                        │                 │
│  ┌────┴───────────────┴────────────────────────┴──────┐          │
│  │ journal-record  journal-retrieve  journal-digest   │          │
│  │ journal-relate  journal-setup                      │          │
│  └────────────────────────────────────────────────────┘          │
└──────────────────────────────────────────────────────────────────┘
         │               │                        │
         ▼               ▼                        ▼
┌───────────────┐ ┌──────────────┐ ┌──────────────────────────┐
│  Layer 1      │ │  Layer 2     │ │  Layer 3 (THIS PROJECT)  │
│  Memory       │ │  Session     │ │  Durable Journal         │
│  (~2K chars)  │ │  Transcripts │ │  $HERMES_HOME/journal/   │
│  Fast facts   │ │  Recent      │ │  Unlimited, searchable   │
│  Always on    │ │  convos      │ │  Portable markdown       │
└───────────────┘ └──────────────┘ └──────────────────────────┘
```

## Three-Layer Memory Model

### Layer 1: Memory (Hermes built-in)
**Purpose:** High-speed recall of stable facts
**Contents:** Your name, profession, key relationships, preferences
**Limits:** ~2,200 chars total; injected into every turn
**Management:** Updated via `memory` tool when facts change

### Layer 2: Session Transcripts (Hermes built-in)
**Purpose:** Short-to-medium term conversation recall
**Contents:** Raw chat logs
**Limits:** Subject to pruning; not designed for permanent retention
**Management:** Accessed via `session_search` tool

### Layer 3: Durable Journal (THIS PROJECT)
**Purpose:** Permanent, unlimited storage of everything worth remembering
**Contents:** Daily entries, events, ideas, decisions, notes
**Format:** Plain markdown, date-indexed
**Location:** `$HERMES_HOME/journal/` (e.g., `~/.hermes/journal/`) — outside the code repo
**Management:** Created/read by Hermes via scripts; also directly accessible

## Data Flow

### Recording

```
User: "Remember that I finished the Q2 review today"
         │
         ▼
Hermes (journal-record skill)
         │
         ├──► If stable fact:         memory tool (add)
         │
         └──► If journal-worthy:      new-entry.sh → $HERMES_HOME/journal/YYYY/MM-DD-title.md
                                              │
                                              └──► Check remote; warn if none configured
```

### Retrieval

```
User: "What happened in Q2 this year?"
         │
         ▼
Hermes (journal-retrieve skill)
         │
         ├──► If specific fact:       memory tool (recall)
         │
         ├──► If recent conversation:  session_search
         │
         └──► If historical journal:   search.sh / summary.sh / related.sh
                                              │
                                              └──► Synthesize + summarize response
```

## Journal Entry Schema

```markdown
# YYYY-MM-DD: Descriptive Title

## Tags
tag1, tag2, project:name, person:name

## Summary
One or two sentences.

## Details
Free-form markdown content.
Can include lists, code blocks, links, etc.

## People
- Name — context

## Linked
- [[YYYY-MM-DD-related-entry]]
- External links or references
```

## Scripts

| Script | Purpose |
|--------|---------|
| `new-entry.sh` | Creates a dated entry with template (inline or editor mode) |
| `search.sh` | Full-text search with snippets, compact, list, tag, date modes |
| `summary.sh` | Generates summary for any period (weekly/monthly/custom) with tag filter |
| `related.sh` | Finds related entries by shared tags, people, and keywords |
| `release.sh` | Deploys PMA updates to host or Docker targets |
| `setup-pma.sh` | Initializes PMA on a new machine (clone + journal git init) |

## Directory Layout

```
personal-memory-assistant/              ← Code repo (shared, git)
├── README.md
├── docs/
│   ├── PRD.md
│   ├── ARCHITECTURE.md
│   ├── TECH-STACK.md
│   ├── ROADMAP.md
│   ├── CHANGELOG.md
│   ├── RELEASE.md
│   ├── VALIDATION.md
│   └── decisions/
│       └── 001-use-markdown-journal.md
├── config/
│   ├── .env.example
│   └── journal.yaml
├── scripts/
│   ├── new-entry.sh
│   ├── search.sh
│   ├── summary.sh
│   ├── related.sh
│   ├── release.sh
│   └── setup-pma.sh
├── skills/
│   └── productivity/
│       ├── journal-record/
│       ├── journal-retrieve/
│       ├── journal-digest/
│       ├── journal-relate/
│       └── journal-setup/
├── .gitignore
└── LICENSE

$HERMES_HOME/journal/                   ← Journal repo (per-user, separate git)
└── YYYY/
    └── MM-DD-title.md
```

## Environments

| Environment | Instance | Code location | Journal location |
|-------------|----------|---------------|------------------|
| Dev | Host Hermes | `~/projects/personal-memory-assistant/` | `~/.hermes/journal/` |
| Production | Docker hermes-user1 | `/opt/data/projects/personal-memory-assistant/` | `/opt/data/journal/` |
| Production | Docker hermes-user2 | `/opt/data/projects/personal-memory-assistant/` | `/opt/data/journal/` |

Skills are synced from the code repo's `skills/` directory to `~/.hermes/skills/` on release. Docker containers access them via the `~/.hermes/skills` bind mount.

## Hermes Skills

| Skill | Trigger | Backend | Purpose |
|-------|---------|---------|---------|
| `journal-record` | "remember/save/note this" | `new-entry.sh` | Saves user input as a journal entry |
| `journal-retrieve` | "find/search/summarize" | `search.sh`, `summary.sh` | Answers questions from journal |
| `journal-digest` | Cron (Sun 20:00) | `summary.sh -w --save` | Weekly summary, auto-saved + pushed |
| `journal-relate` | "what's related to..." | `related.sh` | Cross-reference mapping |
| `journal-setup` | "set up backup/sync" | git commands | Guides user through remote setup |

## Sync Strategy

- **Daily (11 PM):** `git add -A && git commit && git push` in the journal repo
- **Weekly (Sun 8 PM):** Generate summary, save to journal, then push journal repo
- **Manual:** `./scripts/release.sh --type host --path ~/.hermes` after development
