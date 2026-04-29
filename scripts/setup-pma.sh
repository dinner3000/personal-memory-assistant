#!/usr/bin/env bash
#
# setup-pma.sh — Initialize the Personal Memory Assistant project for a user
#
# Clones or updates the project repo and sets up the per-user journal
# directory inside a Docker container.
#
# Usage:
#   ./scripts/setup-pma.sh                    # Setup for host (dev) user
#   ./scripts/setup-pma.sh user1              # Setup for Docker container user1
#   ./scripts/setup-pma.sh user2              # Setup for Docker container user2
#
# Environment:
#   PMA_REPO    GitHub repo URL (default: https://github.com/dinner3000/personal-memory-assistant.git)
#

set -euo pipefail

PMA_REPO="${PMA_REPO:-https://github.com/dinner3000/personal-memory-assistant.git}"
GITHUB_REMOTE="origin"

usage() {
  echo "Usage: $0 [user]"
  echo "  user    Docker container name (user1, user2). Omit for host (dev)."
  exit 1
}

USER="${1:-}"

setup_on_host() {
  echo "--- Setting up PMA for host (dev) environment ---"
  local pma_dir="$HOME/projects/personal-memory-assistant"

  if [ -d "$pma_dir" ]; then
    echo "Project already exists at $pma_dir"
    echo "Updating via git pull..."
    cd "$pma_dir"
    git pull 2>/dev/null || echo "  (already up to date or no remote)"
  else
    echo "Cloning project to $pma_dir..."
    mkdir -p "$HOME/projects"
    git clone "$PMA_REPO" "$pma_dir"
    cd "$pma_dir"
  fi

  mkdir -p "$pma_dir/journal/$(date +%Y)"
  echo "Journal dir: $pma_dir/journal/"
  echo "Done."
}

setup_in_docker() {
  local container_name="$1"
  local hermes_home="$HOME/.hermes-${container_name}"

  echo "--- Setting up PMA for Docker container: ${container_name} ---"

  # Ensure the Docker container is running
  if ! docker ps --format '{{.Names}}' | grep -q "^hermes-${container_name}$"; then
    echo "Error: Container 'hermes-${container_name}' is not running."
    echo "Start it first and try again."
    exit 1
  fi

  # Inside the container: ~ = /opt/data
  # Clone/update the project at ~/projects/personal-memory-assistant/
  docker exec -u hermes "hermes-${container_name}" bash -c '
    set -euo pipefail
    PMA_DIR="$HOME/projects/personal-memory-assistant"
    PMA_REPO="'"$PMA_REPO"'"

    if [ -d "$PMA_DIR/.git" ]; then
      echo "Project exists. Updating..."
      cd "$PMA_DIR"
      git pull
    else
      echo "Cloning project..."
      mkdir -p "$HOME/projects"
      git clone "$PMA_REPO" "$PMA_DIR"
      cd "$PMA_DIR"
    fi

    mkdir -p "$PMA_DIR/journal/$(date +%Y)"
    echo "Journal dir: $PMA_DIR/journal/"
    echo "JOURNAL_PATH=$PMA_DIR/journal"
    echo "Done."
  '

  echo ""
  echo "Container setup complete. The skills reference ~/projects/personal-memory-assistant"
  echo "which now exists inside the container."
  echo ""
  echo "Note: To set up auto-sync inside this container, run the PMA daily cron"
  echo "job inside Hermes in this container."
}

# ---- Main ----

if [ -z "$USER" ]; then
  setup_on_host
elif [ "$USER" = "user1" ] || [ "$USER" = "user2" ]; then
  setup_in_docker "$USER"
else
  echo "Unknown user: $USER"
  echo "Valid values: (empty for host), user1, user2"
  exit 1
fi
