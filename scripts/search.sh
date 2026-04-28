#!/usr/bin/env bash
#
# search.sh — Full-text search across the journal
#
# Usage:
#   ./scripts/search.sh "query"         # Search content
#   ./scripts/search.sh -f "filename"   # Search by filename
#   ./scripts/search.sh -d YYYY-MM-DD   # Search specific date
#   ./scripts/search.sh -m YYYY-MM      # Search specific month
#   ./scripts/search.sh -t "tag"        # Search by tag
#
# Environment: JOURNAL_PATH (defaults to ./journal)
#

set -euo pipefail

JOURNAL_DIR="${JOURNAL_PATH:-$(dirname "$0")/../journal}"

usage() {
  echo "Usage: $0 [OPTIONS] QUERY"
  echo "Options:"
  echo "  -f          Search by filename (not content)"
  echo "  -d DATE     Limit to specific date (YYYY-MM-DD)"
  echo "  -m MONTH    Limit to specific month (YYYY-MM)"
  echo "  -t TAG      Search for a specific tag"
  echo "  -h          Show this help"
  exit 1
}

SEARCH_TYPE="content"
QUERY=""
DATE_FILTER=""
MONTH_FILTER=""
TAG_FILTER=""

while getopts "fd:m:t:h" opt; do
  case $opt in
    f) SEARCH_TYPE="filename" ;;
    d) DATE_FILTER="$OPTARG" ;;
    m) MONTH_FILTER="$OPTARG" ;;
    t) TAG_FILTER="$OPTARG" ;;
    h) usage ;;
    *) usage ;;
  esac
done
shift $((OPTIND-1))
QUERY="$*"

if [ -z "$QUERY" ] && [ -z "$TAG_FILTER" ]; then
  usage
fi

# Build search path
SEARCH_PATH="$JOURNAL_DIR"
if [ -n "$DATE_FILTER" ]; then
  YEAR="${DATE_FILTER:0:4}"
  SEARCH_PATH="$JOURNAL_DIR/$YEAR"
  # Can narrow further if needed
elif [ -n "$MONTH_FILTER" ]; then
  YEAR="${MONTH_FILTER:0:4}"
  SEARCH_PATH="$JOURNAL_DIR/$YEAR"
fi

if [ "$SEARCH_TYPE" = "filename" ]; then
  find "$SEARCH_PATH" -type f -name "*.md" -iname "*${QUERY}*" 2>/dev/null | sort
elif [ -n "$TAG_FILTER" ]; then
  grep -rli "^## Tags" "$SEARCH_PATH" --include="*.md" 2>/dev/null \
    | xargs grep -li "$TAG_FILTER" 2>/dev/null \
    | sort
else
  grep -rnli "$QUERY" "$SEARCH_PATH" --include="*.md" 2>/dev/null | sort
fi
