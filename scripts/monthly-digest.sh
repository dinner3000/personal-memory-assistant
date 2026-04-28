#!/usr/bin/env bash
#
# monthly-digest.sh — Aggregate all entries for a given month into a summary
#
# Usage:
#   ./scripts/monthly-digest.sh              # Current month
#   ./scripts/monthly-digest.sh 2026-04      # Specific month
#
# Environment: JOURNAL_PATH (defaults to ./journal)
#

set -euo pipefail

JOURNAL_DIR="${JOURNAL_PATH:-$(dirname "$0")/../journal}"

if [ $# -ge 1 ]; then
  YEAR_MONTH="$1"
else
  YEAR_MONTH=$(date "+%Y-%m")
fi

YEAR="${YEAR_MONTH:0:4}"
MONTH="${YEAR_MONTH:5:2}"
MONTH_DIR="${JOURNAL_DIR}/${YEAR}"

if [ ! -d "$MONTH_DIR" ]; then
  echo "No entries found for ${YEAR_MONTH}."
  exit 0
fi

ENTRIES=$(find "$MONTH_DIR" -type f -name "${MONTH}-*.md" 2>/dev/null | sort)

if [ -z "$ENTRIES" ]; then
  echo "No entries found for ${YEAR_MONTH}."
  exit 0
fi

echo "================================================"
echo "  Monthly Digest — ${YEAR_MONTH}"
echo "  Entries: $(echo "$ENTRIES" | wc -l)"
echo "================================================"
echo ""

# Collect tags
echo "--- Tags Across Entries ---"
grep -h "^## Tags" $ENTRIES 2>/dev/null \
  | sed 's/^## Tags//' \
  | tr ',' '\n' \
  | sed 's/^ *//;s/ *$//' \
  | grep -v '^$' \
  | sort -u
echo ""

# List entries with summaries
echo "--- Entries ---"
for entry in $ENTRIES; do
  basename=$(basename "$entry" .md)
  summary=$(grep -A1 "^## Summary" "$entry" 2>/dev/null | tail -1)
  echo "  $basename"
  if [ -n "$summary" ]; then
    echo "    $summary"
  fi
  echo ""
done
