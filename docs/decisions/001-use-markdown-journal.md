# ADR 001: Use Markdown Files for Journal Storage

**Date:** 2026-04-28

**Status:** Accepted

## Context

The Personal Memory Assistant needs a durable storage layer for journal entries that:
- Survives Hermes Agent reinstallation and profile changes
- Is searchable without an external service or database
- Works across platforms (CLI, Telegram, Discord)
- Scales to thousands of entries over 10+ years
- Is human-readable and editable outside the assistant
- Has zero external dependencies

Available options within the assistant's toolset:
1. **Hermes memory tool** — durable but space-limited (~2,200 chars)
2. **Hermes session transcripts** — ephemeral, subject to pruning
3. **Filesystem via write_file/read_file** — unlimited, persistent, directly accessible
4. **External databases** — require a running service or SDK
5. **Cloud APIs** — Notion, Airtable, etc. — require API keys, network, vendor trust

## Decision

Use **plain markdown files on the local filesystem**, organized by `YYYY/MM-DD-title.md`, as the durable journal storage layer.

## Consequences

### Positive

- Zero external dependencies — works offline, no API keys, no services
- Human-readable and editable in any text editor
- Grep-able and find-able with built-in system tools
- Git-trackable for version history and remote backup
- Portable — copy the `journal/` directory anywhere
- No schema migrations — markdown is always valid
- Works from any Hermes platform via the same `write_file`/`read_file` tools

### Negative

- Not searchable by semantic meaning (no embeddings) — requires exact keyword or regex matching
- No built-in deduplication — assistant must check for existing entries before writing
- No automatic indexing — search is O(n) over files (though fast enough for ~10K files with grep)
- Not encrypted by default — sensitive entries need manual encryption or a git-crypt wrapper

### Neutral

- Entry format must be consistent — relies on the assistant (or scripts) to produce valid markdown with the agreed schema
- Date-based directory structure is opinionated — but flexible enough for most queries
