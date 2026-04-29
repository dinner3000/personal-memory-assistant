#!/usr/bin/env bash
#
# release.sh — Deploy PMA updates to a target environment
#
# Run this on the target machine (after SSH'ing in). Supports both
# host (bare metal) and Docker targets.
#
# Usage:
#   ./scripts/release.sh --type host --path ~/.hermes
#   ./scripts/release.sh --type host --path ~/.hermes-user1
#   ./scripts/release.sh --type host --path ~/.hermes-user2
#   ./scripts/release.sh --type docker --container hermes-user1
#   ./scripts/release.sh --type docker --container hermes-user2
#
# What it does:
#   1. Git pull the latest PMA code
#   2. Sync PMA skills to the target's Hermes skills directory
#   3. For Docker targets: update the project inside the container too
#

set -euo pipefail

PMA_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SKILLS_SRC="$PMA_DIR/skills"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

usage() {
  echo "Usage: $0 --type TYPE [--path PATH | --container NAME]"
  echo ""
  echo "  --type host            Target is a host Hermes profile"
  echo "    --path PATH            Hermes home path (e.g., ~/.hermes, ~/.hermes-user1)"
  echo ""
  echo "  --type docker          Target is a Docker container"
  echo "    --container NAME       Docker container name (e.g., hermes-user1)"
  exit 1
}

# ---- Parse args ----

TARGET_TYPE=""
TARGET_PATH=""
TARGET_CONTAINER=""

while [ $# -gt 0 ]; do
  case "$1" in
    --type) TARGET_TYPE="$2"; shift 2 ;;
    --path) TARGET_PATH="$2"; shift 2 ;;
    --container) TARGET_CONTAINER="$2"; shift 2 ;;
    -h|--help) usage ;;
    *) log_error "Unknown arg: $1"; usage ;;
  esac
done

if [ -z "$TARGET_TYPE" ]; then
  log_error "--type is required (host or docker)"
  usage
fi

case "$TARGET_TYPE" in
  host)
    if [ -z "$TARGET_PATH" ]; then
      log_error "--path is required for --type host"
      usage
    fi
    ;;
  docker)
    if [ -z "$TARGET_CONTAINER" ]; then
      log_error "--container is required for --type docker"
      usage
    fi
    ;;
  *)
    log_error "Unknown type: $TARGET_TYPE (use 'host' or 'docker')"
    usage
    ;;
esac

# ---- Sync PMA skills to a Hermes skills directory ----

sync_skills() {
  local hermes_skills="$1/skills/productivity"

  log_info "Syncing PMA skills to $hermes_skills..."

  if [ ! -d "$SKILLS_SRC/productivity" ]; then
    log_warn "No skills found at $SKILLS_SRC/productivity — skipping."
    return
  fi

  mkdir -p "$hermes_skills"

  for skill_dir in "$SKILLS_SRC/productivity"/*/; do
    [ -d "$skill_dir" ] || continue
    skill_name=$(basename "$skill_dir")
    target="$hermes_skills/$skill_name"

    if [ -d "$target" ]; then
      rm -rf "$target"
    fi
    cp -r "$skill_dir" "$target"
    log_info "  Synced skill: $skill_name"
  done
}

# ---- Git pull the project ----

update_project() {
  cd "$PMA_DIR"
  if git remote -v | grep -q "origin"; then
    git pull 2>/dev/null && log_info "Git pull: OK" || log_info "Git pull: up to date"
  fi
}

# ---- Deploy to a host Hermes profile ----

deploy_host() {
  local hermes_home="$1"

  # Expand ~ if present
  hermes_home="${hermes_home/#\~/$HOME}"

  if [ ! -d "$hermes_home" ]; then
    log_error "Hermes home not found: $hermes_home"
    return 1
  fi

  log_info "Deploying to host: $hermes_home"
  update_project
  sync_skills "$hermes_home"
  log_info "Host deploy complete."
}

# ---- Deploy to a Docker container ----

deploy_docker() {
  local container="$1"

  if ! docker ps --format '{{.Names}}' 2>/dev/null | grep -q "^${container}$"; then
    log_error "Container '${container}' is not running."
    return 1
  fi

  log_info "Deploying to Docker container: ${container}"
  update_project

  # Update project inside container
  docker exec -u hermes "$container" bash -c "
    set -euo pipefail
    PMA_DIR=\"\$HOME/projects/personal-memory-assistant\"

    if [ -d \"\$PMA_DIR/.git\" ]; then
      cd \"\$PMA_DIR\"
      git pull 2>/dev/null && echo '  Git pull: OK' || echo '  Git pull: up to date'
    fi

    mkdir -p \"\$PMA_DIR/journal/\$(date +%Y)\"
  "

  # Skills: sync to host's ~/.hermes/skills/ which is mounted into container
  # The container mounts ~/.hermes/skills → /opt/data/skills
  log_info "  Skills: sync to host ~/.hermes/skills/ (mounted into container)..."
  sync_skills "$HOME/.hermes"

  log_info "${container}: deploy complete."
}

# ---- Main ----

echo "━━━ PMA Release ━━━"
echo ""

case "$TARGET_TYPE" in
  host)   deploy_host "$TARGET_PATH" ;;
  docker) deploy_docker "$TARGET_CONTAINER" ;;
esac

log_info "Release complete."
