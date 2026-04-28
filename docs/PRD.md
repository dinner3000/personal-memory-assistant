# Product Requirements Document — Personal Memory Assistant

## Problem Statement

Existing AI assistants have no durable, long-term memory. Conversations are ephemeral sessions. Users lose context, ideas, and important facts between sessions — especially across different platforms (CLI, Telegram, Discord, etc.). Over months and years, this accumulates into significant knowledge loss.

## Target Users

- **Primary:** You (the author) — using Hermes Agent daily across CLI and messaging platforms
- **Secondary:** Anyone running Hermes Agent who wants persistent cross-session memory

## User Stories

### Recording

1. **As a user**, I can tell the assistant something to remember at any time, from any platform.
2. **As a user**, I can share ideas, events, notes, to-dos, people met, and decisions made — and expect them to be captured permanently.
3. **As a user**, I don't need to specify a storage location or format — the assistant handles it.

### Retrieval

4. **As a user**, months or years later, I can ask the assistant about something I told it — and get a correct, contextual answer.
5. **As a user**, I can ask for summaries by time period ("what happened last month"), topic ("everything about Project X"), or people ("what did Alice say about the design?").
6. **As a user**, I can search my journal directly (via grep/scripts) without involving the assistant.

### Maintenance

7. **As a user**, I can review, edit, or delete any past journal entry.
8. **As a user**, I can back up my entire memory to another machine.
9. **As a user**, I can regenerate periodic summaries (monthly, yearly).

## Success Criteria

| Criterion | Measure |
|---|---|
| Durability | Entries survive Hermes reinstall, profile changes, and OS reinstalls |
| Searchability | Any entry can be found within 3 seconds by date, keyword, or tag |
| Cross-platform | Recording and retrieval work from CLI, Telegram, Discord, and any other connected gateway |
| Scale | System handles 10+ years of daily entries (3,650+ files) without degradation |
| Portability | Full journal is a directory tree of plain markdown — portable to any tool |
| Zero data loss | No entries lost due to session pruning, memory caps, or platform changes |

## Out of Scope (v1)

- Vector/embedding-based semantic search (plain-text grep is sufficient for v1)
- Multimedia storage (photos, voice notes — text-only journal for now)
- Collaborative/shared journaling (single-user only)
- Automatic entity extraction or knowledge graph

## Future Considerations

- Embedding-based retrieval for semantic ("find the entry where I felt frustrated") queries
- Automated daily digest email or message
- Integration with calendar, email, and other data sources
