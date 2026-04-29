# Release Guide

## Architecture

| Environment | Instance | Code repo | Journal repo |
|-------------|----------|-----------|-------------|
| **Dev** | Host Hermes (`~/.hermes/`) | `~/projects/personal-memory-assistant/` | `~/.hermes/journal/` |
| **Production** | Docker `hermes-user1` | `/opt/data/projects/personal-memory-assistant/` | `/opt/data/journal/` |
| **Production** | Docker `hermes-user2` | `/opt/data/projects/personal-memory-assistant/` | `/opt/data/journal/` |

**Code and data are separated:**
- **Code** (scripts, skills, config) is shared from one git repo — `dinner3000/personal-memory-assistant`
- **Journal** (entries) lives in `$HERMES_HOME/journal/` — each user has their own independent repo

**Project-scoped skills** (`journal-record`, `journal-retrieve`, `journal-digest`, `journal-relate`)
live in the PMA repo at `skills/productivity/` and are synced to `~/.hermes/skills/` on release.

**General-purpose skills** (`project-bootstrapper`, `project-continue`) live in
`~/projects/hermes-skills/` (a separate repo — GitHub: `dinner3000/hermes-skills`).

## Initial Setup

Run once on each target machine:

```bash
# On the dev machine (host)
./scripts/setup-pma.sh

# On each production machine
# SSH into the target, then:
./scripts/setup-pma.sh

# For Docker containers on the same machine:
./scripts/setup-pma.sh user1
./scripts/setup-pma.sh user2
```

## Release Process

SSH into the target machine, then:

```bash
cd ~/projects/personal-memory-assistant

# Deploy to a host Hermes profile
./scripts/release.sh --type host --path ~/.hermes
./scripts/release.sh --type host --path ~/.hermes-user1

# Deploy to a Docker container
./scripts/release.sh --type docker --container hermes-user1
./scripts/release.sh --type docker --container hermes-user2
```

The release script:
1. Git pull the latest PMA code
2. Sync PMA skills to `~/.hermes/skills/`
3. If targeting Docker containers, also updates the project inside them

Skills are automatically available in Docker containers via the `~/.hermes/skills` bind mount.

## What Gets Released

- **Scripts**: `scripts/new-entry.sh`, `search.sh`, `summary.sh`, `related.sh`
- **Skills**: `skills/productivity/journal-record`, `journal-retrieve`, `journal-digest`, `journal-relate`
- **Config**: `config/journal.yaml`
