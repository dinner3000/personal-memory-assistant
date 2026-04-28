# Tech Stack — Personal Memory Assistant

## Stack Overview

```
┌─────────────────────────────┐
│   Hermes Agent (AI Layer)   │  LLM + tool calling
├─────────────────────────────┤
│   Markdown (Data Layer)     │  Plain-text journal files
├─────────────────────────────┤
│   Filesystem (Storage)      │  Local disk + git remote
├─────────────────────────────┤
│   Bash + grep (Tooling)     │  Scripts for search, entry, backup
└─────────────────────────────┘
```

## Decisions

### Storage: Plain Markdown on Filesystem

**Chosen:** Plain `.md` files organized by `YYYY/MM-DD-title.md`

**Alternatives considered:**

| Option | Verdict | Reason |
|---|---|---|
| SQLite | Rejected | Overkill for text notes; adds schema migration burden; less portable |
| Obsidian vault | Optional | Can point journal at an Obsidian vault if user already uses Obsidian; not required |
| Notion / Airtable | Rejected | Proprietary, no offline access, API-dependent, vendor lock-in |
| Plain markdown | ✅ Selected | Universal, portable, grep-able, version-controllable, zero dependencies |

### Date Organization: YYYY/MM-DD-title.md

**Chosen:** Yearly directories with daily files

**Rationale:**
- Single flat directory doesn't scale past ~1,000 files
- `YYYY/MM-DD-title.md` keeps each year self-contained
- Works with standard globs: `journal/2026/*`, `journal/2026/04*`
- Easy to archive/backup per-year

### Search: grep + find

**Chosen:** `grep -rli` for content search, `find` for filename search

**Rationale:**
- Zero dependencies — built into every Linux/macOS system
- Fast enough for ~10K files (sub-second on modern hardware)
- Can drop in `ripgrep` (`rg`) later if speed becomes an issue, same interface
- No database, no indexing, no maintenance

### Automation: Bash Scripts

**Chosen:** POSIX-compatible shell scripts

**Rationale:**
- Runs anywhere without interpreters or runtimes
- Simple, transparent, easy to modify
- Can be called from Hermes via `terminal` tool

### Version Control: Git + GitHub

**Chosen:** Git for local history, GitHub for remote backup

**Rationale:**
- Full history of every journal entry
- GitHub as off-site backup
- Diff view of changes over time
- Can push/pull across machines

## Dependency Graph

```
Hermes Agent (required)
├── terminal tool       → runs scripts
├── write_file tool     → creates journal entries
├── read_file tool      → reads journal entries
├── memory tool         → stores stable facts
└── session_search      → finds recent conversations

Bash (required)
├── grep                → content search
├── find                → filename search
├── date                → date-based operations
└── cat / less          → reading entries

Git (recommended)
└── GitHub (optional)   → remote backup
```

## Future Tech Considerations

- **ripgrep** (`rg`) — drop-in replacement for `grep`, 5-10x faster on large journals
- **jq** — if structured metadata (JSON frontmatter) is added to entries
- **fzf** — interactive fuzzy search for terminal browsing
- **fswatch / entr** — auto-backup or auto-summary on file changes
