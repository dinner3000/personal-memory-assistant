#!/usr/bin/env bash
#
# setup-pma.sh — Initialize PMA on a target machine
#
# Clones the project, sets up the journal directory, and syncs skills.
# Run once on each target machine (host or Docker container).
#
# Usage:
#   ./scripts/setup-pma.sh                    # Setup for current machine
#   ./scripts/setup-pma.sh hermes-user1       # Setup in Docker container
#   ./scripts/setup-pma.sh hermes-user2       # Setup in Docker container
#

set -euo pipefail

PMA_REPO="${PMA_REPO:-https://github.com/dinner3000/personal-memory-assistant.git}"
PMA_DIR="$(cd "$(dirname "$0")/.." && pwd)"

usage() {
  echo "Usage: $0 [container]"
  echo "  container    Docker container name (e.g., hermes-user1). Omit for host."
  exit 1
}

TARGET="${1:-}"

sync_skills() {
  local pma_skills="$1/skills/productivity"
  local hermes_skills="$HOME/.hermes/skills/productivity"

  if [ ! -d "$pma_skills" ]; then
    echo "  No skills dir at $pma_skills — skipping."
    return
  fi

  mkdir -p "$hermes_skills"

  for skill_dir in "$pma_skills"/*/; do
    [ -d "$skill_dir" ] || continue
    skill_name=$(basename "$skill_dir")
    target="$hermes_skills/$skill_name"

    if [ -d "$target" ]; then
      rm -rf "$target"
    fi
    cp -r "$skill_dir" "$target"
    echo "  Synced skill: $skill_name"
  done
}

setup_local() {
  local hermes_home="${HERMES_HOME:-$HOME/.hermes}"
  local journal_dir="$hermes_home/journal"

  echo "--- Setting up PMA for this machine ---"
  echo "Journal home: $journal_dir"

  if [ -d "$PMA_DIR/.git" ]; then
    echo "Project already exists at $PMA_DIR"
    cd "$PMA_DIR"
    git pull 2>/dev/null || echo "  (already up to date or no remote)"
  else
    echo "Cloning project to $PMA_DIR..."
    mkdir -p "$(dirname "$PMA_DIR")"
    git clone "$PMA_REPO" "$PMA_DIR"
    cd "$PMA_DIR"
  fi

  # Initialize journal directory
  mkdir -p "$journal_dir/$(date +%Y)"
  if [ ! -d "$journal_dir/.git" ]; then
    cd "$journal_dir"
    git init
    git branch -m main
    echo "  Journal git initialized at $journal_dir"
  else
    echo "  Journal git already exists at $journal_dir"
  fi

  sync_skills "$PMA_DIR"
  echo "Done."
}

setup_docker() {
  local container_name="$TARGET"

  if ! docker ps --format '{{.Names}}' | grep -q "^${container_name}$"; then
    echo "Error: Container '${container_name}' is not running."
    exit 1
  fi

  echo "--- Setting up PMA for Docker container: ${container_name} ---"

  # Clone/update the project inside the container (as hermes user)
  docker exec -u hermes "$container_name" bash -c '
    set -euo pipefail
    PMA_DIR="$HOME/projects/personal-memory-assistant"
    JOURNAL_DIR="$HERMES_HOME/journal"
    PMA_REPO="'"$PMA_REPO"'"

    if [ -d "$PMA_DIR/.git" ]; then
      echo "Project exists. Updating..."
      cd "$PMA_DIR"
      git pull
    else
      echo "Cloning project..."
      mkdir -p "$HOME/projects"
      git clone "$PMA_REPO" "$PMA_DIR"
    fi

    # Initialize journal directory
    mkdir -p "$JOURNAL_DIR/$(date +%Y)"
    if [ ! -d "$JOURNAL_DIR/.git" ]; then
      cd "$JOURNAL_DIR"
      git init
      git branch -m main
      echo "  Journal git initialized at $JOURNAL_DIR"
    else
      echo "  Journal git already exists at $JOURNAL_DIR"
    fi
  '

  # Skills are synced via host ~/.hermes/skills mount (already done if host runs setup)
  echo "Skills: synced via host ~/.hermes/skills mount"
  echo "Container setup complete."
}

# ---- Main ----

if [ -z "$TARGET" ]; then
  setup_local
elif docker ps --format '{{.Names}}' 2>/dev/null | grep -q "^${TARGET}$"; then
  setup_docker
else
  echo "Unknown target: $TARGET"
  echo "Provide a running Docker container name (e.g., hermes-user1) or omit for host."
  usage
fi
