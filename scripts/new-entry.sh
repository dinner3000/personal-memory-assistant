#!/usr/bin/env bash
#
# new-entry.sh — Create a new journal entry with today's date
#
# Usage:
#   ./scripts/new-entry.sh "Title"
#       Create template and open $EDITOR (default behavior)
#
#   ./scripts/new-entry.sh -m "Title" [options]
#       Create entry with inline content, no editor
#
# Options (with -m):
#   -s "Summary"    Summary text
#   -d "Details"    Details text (use \n for multi-line)
#   -g "tags"       Comma-separated tags (e.g., "work, project:foo")
#   -p "people"     Comma-separated people (e.g., "Alice, Bob")
#   -l "refs"       Comma-separated linked references
#
# Other:
#   -t              Open editor after creating the template
#   --help          Show this help
#
# Environment:
#   JOURNAL_PATH    Path to journal directory (default: $HERMES_HOME/journal)
#   EDITOR          Editor to use (default: vim)
#

set -euo pipefail

show_help() {
  sed -n '2,26p' "$0" | sed 's/^# //;s/^#$//'
  exit 0
}

# ---- Parse arguments ----

MESSAGE_MODE=false
EDIT_MODE=false
SUMMARY=""
DETAILS=""
TAGS=""
PEOPLE=""
LINKS=""
TITLE=""
DETAILS_FILE=""

while [ $# -gt 0 ]; do
  case "$1" in
    --help) show_help ;;
    -m) MESSAGE_MODE=true; shift ;;
    -t) EDIT_MODE=true; shift ;;
    -s) SUMMARY="$2"; shift 2 ;;
    -d) DETAILS="$2"; shift 2 ;;
    -f) DETAILS_FILE="$2"; shift 2 ;;
    -g) TAGS="$2"; shift 2 ;;
    -p) PEOPLE="$2"; shift 2 ;;
    -l) LINKS="$2"; shift 2 ;;
    -*)
      echo "Unknown option: $1"
      echo "Usage: $0 [-m] [-t] [-s summary] [-d details] [-g tags] [-p people] [-l links] \"Title\""
      exit 1
      ;;
    *)
      if [ -n "$TITLE" ]; then
        TITLE="$TITLE $1"
      else
        TITLE="$1"
      fi
      shift
      ;;
  esac
done

if [ -z "$TITLE" ]; then
  echo "Error: title is required."
  echo "Usage: $0 [-m] [-t] \"Title\""
  exit 1
fi

# ---- Resolve details source ----
if [ -n "$DETAILS_FILE" ]; then
  if [ ! -f "$DETAILS_FILE" ]; then
    echo "Error: details file not found: $DETAILS_FILE"
    exit 1
  fi
  DETAILS=$(cat "$DETAILS_FILE")
elif [ -n "$DETAILS" ]; then
  # Interpret escape sequences in -d string
  DETAILS=$(printf "%b" "$DETAILS")
elif [ ! -t 0 ] && [ "$MESSAGE_MODE" = true ]; then
  # Read from stdin if piped and in message mode
  DETAILS=$(cat)
fi

# ---- Determine paths ----

HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
JOURNAL_DIR="${JOURNAL_PATH:-$HERMES_HOME/journal}"
DATE=$(date "+%Y-%m-%d")
YEAR=$(date "+%Y")
MONTH_DAY=$(date "+%m-%d")

# Generate slug: lowercase, alphanumeric + hyphens only
SLUG=$(echo "$TITLE" \
  | tr '[:upper:]' '[:lower:]' \
  | sed 's/[^a-z0-9]/-/g' \
  | sed 's/--*/-/g' \
  | sed 's/^-//;s/-$//')

# If slug is empty (e.g., all-Chinese title), use a truncated safe version
if [ -z "$SLUG" ]; then
  SLUG=$(echo "$TITLE" \
    | sed 's/[^a-zA-Z0-9]/-/g' \
    | sed 's/--*/-/g' \
    | sed 's/^-//;s/-$//' \
    | tr '[:upper:]' '[:lower:]')
fi
# Absolute last resort
if [ -z "$SLUG" ]; then
  SLUG="entry-$(date '+%H%M%S')"
fi

FILENAME="${MONTH_DAY}-${SLUG}.md"
DIR="${JOURNAL_DIR}/${YEAR}"
FILEPATH="${DIR}/${FILENAME}"

mkdir -p "$DIR"

if [ -f "$FILEPATH" ]; then
  echo "Warning: $FILEPATH already exists. Appending timestamp."
  FILENAME="${MONTH_DAY}-${SLUG}-$(date '+%H%M%S').md"
  FILEPATH="${DIR}/${FILENAME}"
fi

# ---- Build entry ----

build_tags() {
  if [ -n "$TAGS" ]; then
    echo "$TAGS"
  fi
}

build_people() {
  if [ -n "$PEOPLE" ]; then
    echo "$PEOPLE" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | sed 's/, */\n/g' | sed 's/^/- /'
  fi
}

build_links() {
  if [ -n "$LINKS" ]; then
    echo "$LINKS" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | sed 's/, */\n/g' | sed 's/^/- /'
  fi
}

cat > "$FILEPATH" << ENTRY
# ${DATE}: ${TITLE}

## Tags
$(build_tags)

## Summary
${SUMMARY}

## Details
${DETAILS}

## People
$(build_people)

## Linked
$(build_links)
ENTRY

# Trim trailing blank lines from the file
sed -i ':a;/^[[:space:]]*$/{$d;N;ba}' "$FILEPATH" 2>/dev/null || true

# ---- Post-create actions ----

if [ "$MESSAGE_MODE" = false ] || [ "$EDIT_MODE" = true ]; then
  ${EDITOR:-vim} "$FILEPATH"
fi

echo "Created: $FILEPATH"
