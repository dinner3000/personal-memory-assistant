# Changelog

All notable changes to this project are documented here.

Format based on [Keep a Changelog](https://keepachangelog.com/), and this project adheres to [Semantic Versioning](https://semver.org/).

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
