# Personal Memory Assistant

A persistent, searchable life/work memory system powered by [Hermes Agent](https://hermes-agent.nousresearch.com).

**The problem:** You can drop into any Hermes chat session — CLI, Telegram, Discord — and tell me something to remember. Months later, in a different session, you can ask and I'll retrieve it. But raw session transcripts get pruned, and memory has a size limit. This project builds a durable, scalable layer on top.

**The solution:** A two-layer memory model — Hermes's built-in `memory` tool for stable facts about you, plus a date-structured markdown journal on disk for everything else. I write entries automatically when you tell me things. I search and summarize when you ask.

## Quick Start

```bash
# Clone or create
git clone https://github.com/YOUR_USER/personal-memory-assistant.git
cd personal-memory-assistant

# Set up env (optional — only needed if you use Obsidian)
cp config/.env.example .env
# Edit .env with your paths

# Create your first journal entry
./scripts/new-entry.sh "Initial setup complete"
```

## How It Works

```
You tell me something ──► Hermes session
                              │
                    ┌─────────┴──────────┐
                    ▼                    ▼
             memory tool            journal/YYYY/MM-DD-*.md
          (stable facts,           (everything else,
           ~2K chars)              unlimited, searchable)
                    │                    │
                    └─────────┬──────────┘
                              ▼
                      You ask later ──► I search + summarize
```

## Project Docs

| Document | What it covers |
|---|---|
| [docs/PRD.md](docs/PRD.md) | Requirements, user stories, success criteria |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | System design, data flow, component model |
| [docs/TECH-STACK.md](docs/TECH-STACK.md) | Technology choices and rationale |
| [docs/ROADMAP.md](docs/ROADMAP.md) | Phases and future plans |
| [docs/CHANGELOG.md](docs/CHANGELOG.md) | What's been done, when |
| [docs/RELEASE.md](docs/RELEASE.md) | Dev/prod architecture, deploy instructions |
| [docs/VALIDATION.md](docs/VALIDATION.md) | Test scenarios and acceptance criteria |
| [docs/decisions/](docs/decisions/) | Architecture Decision Records |
| [skills/productivity/](skills/productivity/) | Hermes skills (journal-record, etc.) |

## License

MIT
