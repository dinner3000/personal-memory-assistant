#!/usr/bin/env bash
#
# release.sh — Deploy PMA updates to the current environment
#
# Run this on the target machine (after SSH'ing in) to update PMA.
#
# Usage:
#   ./scripts/release.sh                    # Deploy to all local environments
#   ./scripts/release.sh host               # Deploy to host Hermes only
#   ./scripts/release.sh user1              # Deploy to Docker container user1
#   ./scripts/release.sh user2              # Deploy to Docker container user2
#
# What it does:
#   1. Git pull the latest PMA code
#   2. Sync PMA skills to ~/.hermes/skills/
#   3. For Docker targets: update the container too
#

set -euo pipefail

PMA_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SKILLS_SRC="$PMA_DIR/skills"
HERMES_SKILLS_DIR="$HOME/.hermes/skills/productivity"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

usage() {
  echo "Usage: $0 [target]"
  echo "  target    'host', 'user1', 'user2', or empty (all local)"
  exit 1
}

# ---- Sync PMA skills to Hermes skills dir ----

sync_skills() {
  log_info "Syncing PMA skills to $HERMES_SKILLS_DIR..."

  if [ ! -d "$SKILLS_SRC/productivity" ]; then
    log_warn "No skills found at $SKILLS_SRC/productivity — skipping."
    return
  fi

  mkdir -p "$HERMES_SKILLS_DIR"

  for skill_dir in "$SKILLS_SRC/productivity"/*/; do
    skill_name=$(basename "$skill_dir")
    target="$HERMES_SKILLS_DIR/$skill_name"

    if [ -d "$target" ]; then
      rm -rf "$target"
    fi
    cp -r "$skill_dir" "$target"
    log_info "  Synced skill: $skill_name"
  done
}

# ---- Update project on host ----

update_host() {
  log_info "Updating host environment..."

  cd "$PMA_DIR"
  if git remote -v | grep -q "origin"; then
    git pull 2>/dev/null && log_info "Git pull: OK" || log_info "Git pull: up to date"
  fi

  sync_skills
  log_info "Host update complete."
}

# ---- Update Docker container ----

update_docker() {
  local container_name="hermes-$1"

  if ! docker ps --format '{{.Names}}' | grep -q "^${container_name}$"; then
    log_error "Container '${container_name}' is not running."
    return 1
  fi

  log_info "Updating container ${container_name}..."

  # Update project inside container
  docker exec -u hermes "$container_name" bash -c '
    set -euo pipefail
    PMA_DIR="$HOME/projects/personal-memory-assistant"

    if [ -d "$PMA_DIR/.git" ]; then
      cd "$PMA_DIR"
      git pull 2>/dev/null && echo "  Git pull: OK" || echo "  Git pull: up to date"
    fi

    mkdir -p "$PMA_DIR/journal/$(date +%Y)"
    echo "  Journal dir ready"
  '

  # Skills are shared via ~/.hermes/skills mount — already synced by host step
  log_info "${container_name}: update complete."
}

# ---- Main ----

TARGET="${1:-all}"

echo "━━━ PMA Release ━━━"
echo ""

case "$TARGET" in
  all)
    update_host
    echo ""
    # Auto-detect Docker containers
    for container in hermes-user1 hermes-user2; do
      if docker ps --format '{{.Names}}' 2>/dev/null | grep -q "^${container}$"; then
        update_docker "${container#hermes-}"
        echo ""
      fi
    done
    ;;
  host)
    update_host
    ;;
  user1|user2)
    if docker ps --format '{{.Names}}' 2>/dev/null | grep -q "^hermes-${TARGET}$"; then
      update_host
      echo ""
      update_docker "$TARGET"
    else
      log_error "Container 'hermes-${TARGET}' not found."
      exit 1
    fi
    ;;
  *)
    log_error "Unknown target: $TARGET"
    usage
    ;;
esac

log_info "Release complete."
