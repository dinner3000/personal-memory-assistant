# Changelog

All notable changes to this project are documented here.

Format based on [Keep a Changelog](https://keepachangelog.com/), and this project adheres to [Semantic Versioning](https://semver.org/).

## [1.1.0] — 2026-04-29

### Changed

- **Journal separated from project repo** — journal is now at `$HERMES_HOME/journal/` (per-user)
  - Scripts default to `$HERMES_HOME/journal/` (fallback `~/.hermes/journal/`)
  - Each user has their own journal git repo with data isolation
  - Project repo now tracks only code (scripts, skills, config, docs)
  - Daily cron pushes journal repo; weekly digest saves to journal repo
- **Release script** redesigned with `--type host --path PATH` and `--type docker --container NAME`
- **Setup script** creates per-user journal git repo automatically

## [1.0.0] — 2026-04-29

### Added

- **Release workflow** — `scripts/release.sh` deploys updates to Docker containers
- **Setup script** — `scripts/setup-pma.sh` initializes PMA in any environment
- **Release guide** — `docs/RELEASE.md` documents dev/prod architecture

### Changed

- Phase 6 reorganized: deferred data-heavy items, marked weekly digest as done
- Phase 5 completed: daily sync cron, mobile access via git clone + Obsidian

## [0.9.0] — 2026-04-29

### Added

- `related.sh` — cross-reference and relationship mapping between entries
  - Finds related entries by shared tags (2 pts), people (2 pts), keywords (1 pt)
  - Accepts filename fragment, full path, or title as input
  - Sorted by relevance score with optional breakdown (`-t`)
  - `-n N` to limit results
- `journal-relate` Hermes skill — "what's related to [entry]?"

## [0.8.0] — 2026-04-29

### Added

- `summary.sh --tag TAG` — filter summary to entries with a specific tag
- `search.sh -t "tag1,tag2"` — multi-tag OR search (comma-separated)
- Tag matching is now case-insensitive across all tag search functions

## [0.7.0] — 2026-04-29

### Added

- `journal-digest` Hermes skill — weekly summary generation
- Weekly cron job `pma-weekly-digest` runs every Sunday at 20:00
  - Generates a 7-day summary via `summary.sh -w --save`
  - Auto-commits and pushes to GitHub
  - No manual intervention needed

## [0.6.0] — 2026-04-29

### Added

- `journal-retrieve` Hermes skill — searches and summarizes journal entries on demand
  - Triggered by "find...", "search for...", "what did I do...", "summarize..."
  - Uses search.sh and summary.sh as backends
  - Presents results naturally, offers to record if nothing found
  - Stored at ~/projects/hermes-skills/productivity/journal-retrieve/

## [0.5.0] — 2026-04-28

### Added

- `journal-record` Hermes skill — records journal entries from natural language
  - Triggered by phrases like "remember that..." or "save this..."
  - Extracts title, summary, details, tags, and people from conversational input
  - Uses new-entry.sh as backend
  - Stored at ~/projects/hermes-skills/productivity/journal-record/

## [0.4.0] — 2026-04-28

### Added

- `summary.sh` — flexible journal summary generator
  - `-w` (default): summary of last 7 days
  - `-m [YYYY-MM]`: summary of a month
  - `-f YYYY-MM-DD -t YYYY-MM-DD`: custom date range
  - `--save`: write summary as a journal entry
  - Tag frequency table with ASCII bars
  - Timeline with entry titles and summaries
  - People aggregation with mention counts

### Fixed

- `new-entry.sh`: `-p "Alice, Bob"` no longer produces double dash `- - Bob` for subsequent people
- `summary.sh`: `extract_title` strips date prefix, people names are cleaned

## [0.3.0] — 2026-04-28

### Added

- `search.sh` now fully functional with four output modes
  - Default: content search with 2-line context snippets and match highlighting
  - `-c`: compact mode — match counts per file
  - `-l`: list mode — file paths only
  - `-f`: search by filename pattern
  - `-d YYYY-MM-DD`: restrict search to a single date
  - `-m YYYY-MM`: restrict search to a month
  - `-t tag`: search within the Tags section
  - Summary line: "N matches in M file(s)"
  - Color highlighting when output is a terminal

## [0.2.0] — 2026-04-28

### Added

- `new-entry.sh` now fully functional with three input modes
  - `-m "Title"` message mode: inline entry, no editor needed
  - `-d "details"` with `\n` escape sequences for multi-line content
  - stdin piping for details (pipe content into the script)
  - `-g tags`, `-p people`, `-l links`, `-f file` flags
  - `-t` flag to open editor after creating
  - `--help` flag with usage reference

## [0.1.0] — 2026-04-28

### Added

- Project scaffold: docs, config, scripts, journal directories
- README.md — project overview and quick start
- PRD.md — product requirements with user stories
- ARCHITECTURE.md — three-layer memory model design
- TECH-STACK.md — technology decisions and rationale
- ROADMAP.md — phased development plan (6 phases)
- VALIDATION.md — test scenarios and acceptance criteria
- First ADR: 001-use-markdown-journal.md
- Config templates: .env.example, journal.yaml
- Script stubs: new-entry.sh, search.sh, monthly-digest.sh, backup.sh
- .gitignore for markdown journal projects
- MIT License
- Git repository initialized and pushed to GitHub
