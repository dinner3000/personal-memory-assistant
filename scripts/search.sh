#!/usr/bin/env bash
#
# search.sh — Full-text search across the journal
#
# Usage:
#   ./scripts/search.sh "query"           # Search content (default, with snippets)
#   ./scripts/search.sh -c "query"        # Compact: show match counts per file
#   ./scripts/search.sh -l "query"        # List files only
#   ./scripts/search.sh -d YYYY-MM-DD     # Search specific date
#   ./scripts/search.sh -m YYYY-MM        # Search specific month
#   ./scripts/search.sh -t "tag"        # Search by tag
#   ./scripts/search.sh -t "tag1,tag2"  # Search by multiple tags (OR)(in Tags section)
#   ./scripts/search.sh -f "pattern"      # Search by filename
#
# Options:
#   -c        Compact mode — show match count per file
#   -l        List mode — show file paths only
#   -d DATE   Restrict to a single date (YYYY-MM-DD)
#   -m MONTH  Restrict to a month (YYYY-MM)
#   -t TAG    Search by tag (comma-separated for multiple OR)
#   -f        Search by filename (pattern matched against filename)
#   -h        Show this help
#
# Environment: JOURNAL_PATH (defaults to ./journal)
#

set -euo pipefail

JOURNAL_DIR="${JOURNAL_PATH:-$(cd "$(dirname "$0")/.." && pwd)/journal}"

if [ ! -d "$JOURNAL_DIR" ]; then
  echo "Error: journal directory not found at $JOURNAL_DIR"
  echo "Set JOURNAL_PATH to override."
  exit 1
fi

CONTEXT_LINES=2
MODE="snippet"   # snippet | count | list
QUERY_FILENAME=""
DATE_FILTER=""
MONTH_FILTER=""
TAG_FILTER=""

usage() {
  sed -n '2,24p' "$0" | sed 's/^# //;s/^#$//'
  exit 0
}

while getopts "cld:m:t:fh" opt; do
  case $opt in
    c) MODE="count" ;;
    l) MODE="list" ;;
    d) DATE_FILTER="$OPTARG" ;;
    m) MONTH_FILTER="$OPTARG" ;;
    t) TAG_FILTER="$OPTARG" ;;
    f) MODE="filename" ;;
    h) usage ;;
    *) usage ;;
  esac
done
shift $((OPTIND-1))

QUERY="$*"

# Validate: need at least a query, tag filter, or filename mode
if [ -z "$QUERY" ] && [ -z "$TAG_FILTER" ] && [ "$MODE" != "filename" ]; then
  usage
fi

# Convert comma-separated tags to grep -E pattern (OR logic)
TAG_PATTERN=""
if [ -n "$TAG_FILTER" ]; then
  TAG_PATTERN=$(echo "$TAG_FILTER" | sed 's/, */|/g')
fi

# ---- Build search path ----

SEARCH_PATH="$JOURNAL_DIR"
FILE_PATTERN="*.md"

if [ -n "$DATE_FILTER" ]; then
  YEAR="${DATE_FILTER:0:4}"
  FILE_PATTERN="${DATE_FILTER:5:2}-${DATE_FILTER:8:2}-*.md"
  SEARCH_PATH="$JOURNAL_DIR/$YEAR"
elif [ -n "$MONTH_FILTER" ]; then
  YEAR="${MONTH_FILTER:0:4}"
  FILE_PATTERN="${MONTH_FILTER:5:2}-*.md"
  SEARCH_PATH="$JOURNAL_DIR/$YEAR"
fi

if [ ! -d "$SEARCH_PATH" ]; then
  echo "No entries found for this date range."
  exit 0
fi

# ---- Check for color support ----
COLOR_FLAG=""
if [ -t 1 ]; then
  COLOR_FLAG="--color=always"
else
  COLOR_FLAG="--color=never"
fi

# ---- grep wrapper ----
# Returns lines like: path/file.md:lineno:matched line
# with 2 lines of surrounding context

run_grep() {
  local pattern="$1"
  if [ -z "$pattern" ]; then
    return 1
  fi
  grep -rn "$COLOR_FLAG" -C "$CONTEXT_LINES" "$pattern" "$SEARCH_PATH" \
    --include="$FILE_PATTERN" 2>/dev/null || true
}

count_grep() {
  local pattern="$1"
  if [ -z "$pattern" ]; then
    return 1
  fi
  grep -rnc "$pattern" "$SEARCH_PATH" --include="$FILE_PATTERN" 2>/dev/null \
    | grep -v ':0$' || true
}

list_grep() {
  local pattern="$1"
  if [ -z "$pattern" ]; then
    return 1
  fi
  grep -rli "$pattern" "$SEARCH_PATH" --include="$FILE_PATTERN" 2>/dev/null \
    | sort || true
}

# Extended-regex versions for tag pattern matching (OR logic)
run_grep_extended() {
  local pattern="$1"
  if [ -z "$pattern" ]; then
    return 1
  fi
  grep -rniE "$COLOR_FLAG" -C "$CONTEXT_LINES" "$pattern" "$SEARCH_PATH" \
    --include="$FILE_PATTERN" 2>/dev/null || true
}

count_grep_extended() {
  local pattern="$1"
  if [ -z "$pattern" ]; then
    return 1
  fi
  grep -rnicE "$pattern" "$SEARCH_PATH" --include="$FILE_PATTERN" 2>/dev/null \
    | grep -v ':0$' || true
}

list_grep_extended() {
  local pattern="$1"
  if [ -z "$pattern" ]; then
    return 1
  fi
  grep -rliE "$pattern" "$SEARCH_PATH" --include="$FILE_PATTERN" 2>/dev/null \
    | sort || true
}

# ---- Execute ----

TOTAL_FILES=0
TOTAL_MATCHES=0

case "$MODE" in
  filename)
    # Search by filename
    RESULTS=$(find "$SEARCH_PATH" -type f -name "$FILE_PATTERN" -iname "*${QUERY}*" 2>/dev/null | sort)
    if [ -z "$RESULTS" ]; then
      echo "No files found matching \"$QUERY\"."
      exit 0
    fi
    TOTAL_FILES=$(echo "$RESULTS" | wc -l)
    echo "$RESULTS"
    echo ""
    echo "--- $TOTAL_FILES file(s) found ---"
    ;;

  count)
    # Compact: show file + match count
    if [ -n "$TAG_FILTER" ]; then
      # For tag search, count files containing any of the tags in the Tags section
      RESULTS=$(list_grep_extended "$TAG_PATTERN" | while IFS= read -r f; do
        count=$(grep -ciE "$TAG_PATTERN" "$f" 2>/dev/null || true)
        echo "$f:$count"
      done)
    else
      RESULTS=$(count_grep "$QUERY")
    fi
    if [ -z "$RESULTS" ]; then
      echo "No matches found."
      exit 0
    fi
    TOTAL_FILES=$(echo "$RESULTS" | wc -l)
    TOTAL_MATCHES=$(echo "$RESULTS" | awk -F: '{s+=$NF}END{print s}')
    echo "$RESULTS"
    echo ""
    echo "--- $TOTAL_MATCHES matches in $TOTAL_FILES file(s) ---"
    ;;

  list)
    # File paths only
    if [ -n "$TAG_FILTER" ]; then
      RESULTS=$(list_grep_extended "$TAG_PATTERN")
    else
      RESULTS=$(list_grep "$QUERY")
    fi
    if [ -z "$RESULTS" ]; then
      echo "No matches found."
      exit 0
    fi
    TOTAL_FILES=$(echo "$RESULTS" | wc -l)
    echo "$RESULTS"
    echo ""
    echo "--- $TOTAL_FILES file(s) ---"
    ;;

  snippet|*)
    # Default: snippet mode with context
    if [ -n "$TAG_FILTER" ]; then
      # For tag search, grep the Tags section specifically
      # Find files with ## Tags section, then check if the tag is within that section
      RESULTS=$(list_grep "^## Tags" | while IFS= read -r f; do
        # Check if tag appears within 5 lines after ## Tags
        if grep -A5 "^## Tags" "$f" 2>/dev/null | grep -qiE "$TAG_PATTERN"; then
          # Show the matching line with context, force file path with -H
          grep -nHi "$COLOR_FLAG" -C "$CONTEXT_LINES" -E "$TAG_PATTERN" "$f" 2>/dev/null
          echo "--"
        fi
      done)
    else
      RESULTS=$(run_grep "$QUERY")
    fi
    if [ -z "$RESULTS" ]; then
      echo "No matches found."
      exit 0
    fi
    # Count actual matches (lines matching the file:lineno: pattern)
    if [ -n "$TAG_FILTER" ]; then
      # Count files that actually have the tag in the Tags section
      TOTAL_FILES=$(echo "$RESULTS" | grep -c "^--$" || true)
      TOTAL_FILES=$((TOTAL_FILES))
    else
      TOTAL_FILES=$(list_grep "$QUERY" | wc -l)
    fi
    TOTAL_MATCHES=$(echo "$RESULTS" | grep -c "^[^/]*/[^:]*:[0-9]\+:" || true)
    echo "$RESULTS"
    echo ""
    echo "--- $TOTAL_MATCHES matches in $TOTAL_FILES file(s) ---"
    ;;
esac
