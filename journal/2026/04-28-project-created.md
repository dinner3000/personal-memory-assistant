# 2026-04-28: Project created — Personal Memory Assistant

## Tags
project:personal-memory-assistant, decisions

## Summary
Created the personal memory assistant project — a structured journal system integrated with Hermes Agent for long-term life/work memory.

## Details
Full project scaffold built:
- Project directory: ~/personal-memory-assistant/
- Docs: PRD, Architecture, Tech Stack, Roadmap, Changelog, Validation, ADRs
- Config: .env.example, journal.yaml
- Scripts: new-entry.sh, search.sh, monthly-digest.sh, backup.sh
- Git initialized and will be pushed to GitHub
- First ADR: "Use Markdown Files for Journal Storage"

The system uses a three-layer memory model:
1. Hermes memory tool (~2K chars) — stable facts about the user
2. Session transcripts — recent conversations
3. Durable markdown journal (this file) — everything else, unlimited

## People
- Gary — me, the user and author

## Linked
- [[ADR 001: Use Markdown Files for Journal Storage]]
