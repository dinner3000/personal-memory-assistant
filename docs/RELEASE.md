# Release Guide

## Architecture

| Environment | Instance | Location | Purpose |
|-------------|----------|----------|---------|
| **Dev** | Host Hermes | `~/.hermes/` | Development, debugging, testing |
| **Production** | Docker `hermes-user1` | `~/.hermes-user1/` | Production user 1 |
| **Production** | Docker `hermes-user2` | `~/.hermes-user2/` | Production user 2 |

**Skills** are shared across all instances via symlinks from `~/.hermes/skills/` → `~/projects/hermes-skills/`.

## Initial Setup

Run once to initialize the project inside each production container:

```bash
# Dev (host) — already set up
./scripts/setup-pma.sh

# Production containers
./scripts/setup-pma.sh user1
./scripts/setup-pma.sh user2
```

## Release Process

After making changes in the dev environment:

```bash
# Deploy to all production containers
./scripts/release.sh

# Or deploy to a single container
./scripts/release.sh user1
```

The release script will:
1. Verify all changes are committed
2. Push to GitHub
3. Pull the latest code into each production container

## What Gets Released

- **Scripts**: `new-entry.sh`, `search.sh`, `summary.sh`, `related.sh`
- **Config**: `journal.yaml`, `.env.example`
- **Hermes skills**: Updated via the shared `~/.hermes/skills/` mount (no deploy needed)

## Data Isolation

Each production container has its own journal directory:
- `hermes-user1`: `~/.hermes-user1/projects/personal-memory-assistant/journal/`
- `hermes-user2`: `~/.hermes-user2/projects/personal-memory-assistant/journal/`

Scripts and config are shared from the same git repo.
