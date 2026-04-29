#!/usr/bin/env bash
#
# release.sh — Release the Personal Memory Assistant to Docker containers
#
# 1. Commits any pending changes and pushes to GitHub
# 2. Updates the project in each production Docker container
#
# Usage:
#   ./scripts/release.sh          # Push + deploy to all containers
#   ./scripts/release.sh user1    # Push + deploy to a single container
#
# Environment:
#   PMA_REPO    GitHub repo URL (default: https://github.com/dinner3000/personal-memory-assistant.git)
#

set -euo pipefail

PMA_REPO="${PMA_REPO:-https://github.com/dinner3000/personal-memory-assistant.git}"
PMA_DIR="$HOME/projects/personal-memory-assistant"
PROD_CONTAINERS=("hermes-user1" "hermes-user2")

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

usage() {
  echo "Usage: $0 [container]"
  echo "  container    Specific container to deploy to (e.g., 'user1'). Omit for all."
  exit 1
}

# ---- Step 1: Verify and push source repo ----

push_source() {
  log_info "Step 1: Pushing source to GitHub..."

  if [ ! -d "$PMA_DIR/.git" ]; then
    log_error "Not a git repository: $PMA_DIR"
    exit 1
  fi

  cd "$PMA_DIR"

  # Check for uncommitted changes
  if [ -n "$(git status --porcelain)" ]; then
    log_warn "Uncommitted changes found."
    echo "  The following files are not committed:"
    git status --short
    echo ""
    echo "  Commit them first, or stash with: git stash"
    exit 1
  fi

  # Check branch
  BRANCH=$(git rev-parse --abbrev-ref HEAD)
  log_info "Current branch: $BRANCH"

  # Check if remote is reachable
  if git remote -v | grep -q "origin"; then
    log_info "Pushing to origin/$BRANCH..."
    git push origin "$BRANCH"
    log_info "Source pushed successfully."
  else
    log_warn "No remote configured. Skipping push."
  fi
}

# ---- Step 2: Deploy to a container ----

deploy_to_container() {
  local container="$1"
  local full_name="hermes-${container}"

  log_info "Deploying to ${full_name}..."

  # Check container is running
  if ! docker ps --format '{{.Names}}' | grep -q "^${full_name}$"; then
    log_error "Container '${full_name}' is not running."
    return 1
  fi

  # Update the project inside the container (as hermes user)
  docker exec -u hermes "$full_name" bash -c '
    set -euo pipefail
    PMA_DIR="$HOME/projects/personal-memory-assistant"
    PMA_REPO="'"$PMA_REPO"'"

    if [ -d "$PMA_DIR/.git" ]; then
      echo "  Pulling latest in $PMA_DIR..."
      cd "$PMA_DIR"
      git pull
    else
      echo "  Cloning repo to $PMA_DIR..."
      mkdir -p "$HOME/projects"
      git clone "$PMA_REPO" "$PMA_DIR"
    fi

    # Ensure journal directory exists
    mkdir -p "$PMA_DIR/journal/$(date +%Y)"
    echo "  Journal dir ready at $PMA_DIR/journal/"
    echo "  Deploy complete for this container."
  '

  if [ $? -eq 0 ]; then
    log_info "${full_name}: deployed successfully."
  else
    log_error "${full_name}: deploy failed."
    return 1
  fi
}

# ---- Main ----

echo "━━━ PMA Release Script ━━━"
echo ""

TARGET="${1:-all}"

# Step 1: Push source
push_source

echo ""

# Step 2: Deploy
if [ "$TARGET" = "all" ]; then
  log_info "Step 2: Deploying to all production containers..."
  for container in "${PROD_CONTAINERS[@]}"; do
    short_name="${container#hermes-}"
    deploy_to_container "$short_name"
    echo ""
  done
elif [ "$TARGET" = "user1" ] || [ "$TARGET" = "user2" ]; then
  log_info "Step 2: Deploying to ${TARGET}..."
  deploy_to_container "$TARGET"
else
  log_error "Unknown target: $TARGET"
  exit 1
fi

log_info "Release complete!"
echo ""
echo "Production containers:"
for container in "${PROD_CONTAINERS[@]}"; do
  echo "  - ${container}: $(docker ps --format '{{.Status}}' --filter name="${container}" 2>/dev/null || echo 'not running')"
done
