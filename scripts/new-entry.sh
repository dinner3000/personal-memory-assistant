#!/usr/bin/env bash
#
# new-entry.sh — Create a new journal entry with today's date
#
# Usage:
#   ./scripts/new-entry.sh "Title of the entry"
#   ./scripts/new-entry.sh -t "Title"  # opens $EDITOR for details
#
# Environment: JOURNAL_PATH (defaults to ./journal)
#

set -euo pipefail

JOURNAL_DIR="${JOURNAL_PATH:-$(dirname "$0")/../journal}"
DATE=$(date "+%Y-%m-%d")
YEAR=$(date "+%Y")
MONTH_DAY=$(date "+%m-%d")

# Get title
if [ $# -eq 0 ]; then
  echo "Usage: $0 [-t] \"Title of entry\""
  echo "  -t    Open editor after creating the template"
  exit 1
fi

EDIT_MODE=false
if [ "$1" = "-t" ]; then
  EDIT_MODE=true
  shift
fi

TITLE="$*"
SLUG=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//')
FILENAME="${MONTH_DAY}-${SLUG}.md"
DIR="${JOURNAL_DIR}/${YEAR}"
FILEPATH="${DIR}/${FILENAME}"

mkdir -p "$DIR"

if [ -f "$FILEPATH" ]; then
  echo "Warning: $FILEPATH already exists. Appending timestamp to filename."
  FILENAME="${MONTH_DAY}-${SLUG}-$(date '+%H%M%S').md"
  FILEPATH="${DIR}/${FILENAME}"
fi

cat > "$FILEPATH" << ENTRY
# ${DATE}: ${TITLE}

## Tags


## Summary


## Details


## People


## Linked

ENTRY

if [ "$EDIT_MODE" = true ]; then
  ${EDITOR:-vim} "$FILEPATH"
fi

echo "Created: $FILEPATH"
