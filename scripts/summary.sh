#!/usr/bin/env bash
#
# summary.sh — Generate a summary of journal entries over a time period
#
# Usage:
#   ./scripts/summary.sh              # Last 7 days (default)
#   ./scripts/summary.sh -w           # Last 7 days
#   ./scripts/summary.sh -m           # Current month
#   ./scripts/summary.sh -m 2026-04   # Specific month
#   ./scripts/summary.sh -f 2026-04-20 -t 2026-04-25  # Custom range
#   ./scripts/summary.sh -w --save    # Save summary as a journal entry
#   ./scripts/summary.sh --tag "work"  # Only entries tagged "work"
#
# Options:
#   -w              Weekly (last 7 days) — default
#   -m [YYYY-MM]    Monthly (current or specified)
#   -f YYYY-MM-DD   From date (start of range)
#   -t YYYY-MM-DD   To date (end of range)
#   --tag TAG       Filter by tag (e.g., "work", "learning")
#   --save          Save summary as a journal entry instead of printing
#   -h              Show this help
#
# Environment: JOURNAL_PATH (defaults to ./journal)
#

set -euo pipefail

JOURNAL_DIR="${JOURNAL_PATH:-$(cd "$(dirname "$0")/.." && pwd)/journal}"

if [ ! -d "$JOURNAL_DIR" ]; then
  echo "Error: journal directory not found at $JOURNAL_DIR"
  exit 1
fi

MODE="week"
FROM_DATE=""
TO_DATE=""
SAVE_MODE=false
TAG_FILTER=""

usage() {
  sed -n '2,20p' "$0" | sed 's/^# //;s/^#$//'
  exit 0
}

while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help) usage ;;
    -w) MODE="week"; shift ;;
    -m) MODE="month"
        if [ $# -ge 2 ] && [[ "$2" =~ ^[0-9]{4}-[0-9]{2}$ ]]; then
          FROM_DATE="$2-01"
          shift
        fi
        shift ;;
    -f) FROM_DATE="$2"; shift 2 ;;
    -t) TO_DATE="$2"; shift 2 ;;
    --save) SAVE_MODE=true; shift ;;
    --tag) TAG_FILTER="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; usage ;;
  esac
done

# ---- Resolve date range ----

if [ "$MODE" = "week" ] && [ -z "$FROM_DATE" ]; then
  # Last 7 days
  FROM_DATE=$(date -d "7 days ago" "+%Y-%m-%d")
  TO_DATE=$(date "+%Y-%m-%d")
elif [ "$MODE" = "month" ] && [ -z "$FROM_DATE" ]; then
  # Current month
  FROM_DATE=$(date "+%Y-%m-01")
  TO_DATE=$(date "+%Y-%m-%d")
elif [ "$MODE" = "month" ] && [ -n "$FROM_DATE" ]; then
  # Specific month — FROM_DATE was set from -m arg, compute end of month
  YM="${FROM_DATE:0:7}"
  # Last day of that month
  TO_DATE=$(date -d "$YM-01 +1 month -1 day" "+%Y-%m-%d")
fi

if [ -z "$FROM_DATE" ] || [ -z "$TO_DATE" ]; then
  echo "Error: could not determine date range."
  echo "Usage: $0 [-w] [-m YYYY-MM] [-f YYYY-MM-DD -t YYYY-MM-DD]"
  exit 1
fi

# ---- Collect entries within date range ----

ENTRIES=()
ENTRY_FILES=()
TAGS_LIST=()
PEOPLE_LIST=()

collect_entries() {
  while IFS= read -r -d '' file; do
    # Extract date from path: .../YYYY/MM-DD-title.md
    dir=$(dirname "$file")
    year=$(basename "$dir")
    basename=$(basename "$file" .md)
    mmdd="${basename:0:5}"   # MM-DD
    entry_date="${year}-${mmdd}"

    # Compare dates
    if [[ "$entry_date" > "$TO_DATE" ]]; then
      continue
    fi
    if [[ "$entry_date" < "$FROM_DATE" ]]; then
      continue
    fi

    ENTRY_FILES+=("$file")
    ENTRIES+=("$entry_date|$basename|$file")
  done < <(find "$JOURNAL_DIR" -type f -name "*.md" -print0 2>/dev/null | sort -z)
}

collect_entries

if [ ${#ENTRIES[@]} -eq 0 ]; then
  echo "No entries found from $FROM_DATE to $TO_DATE."
  exit 0
fi

# Sort by date
IFS=$'\n' ENTRIES=($(sort <<<"${ENTRIES[*]}")); unset IFS

# ---- Extract tags and people ----

extract_tags() {
  local file="$1"
  local tags
  tags=$(grep -A1 "^## Tags" "$file" 2>/dev/null | tail -1)
  echo "$tags"
}

# ---- Filter by tag (if requested) ----

if [ -n "$TAG_FILTER" ]; then
  FILTERED_ENTRIES=()
  for entry in "${ENTRIES[@]}"; do
    file=$(echo "$entry" | cut -d'|' -f3-)
    tags=$(extract_tags "$file")
    if echo "$tags" | grep -qi "$TAG_FILTER"; then
      FILTERED_ENTRIES+=("$entry")
    fi
  done
  ENTRIES=("${FILTERED_ENTRIES[@]}")
fi

if [ -n "$TAG_FILTER" ] && [ ${#ENTRIES[@]} -eq 0 ]; then
  echo "No entries tagged \"$TAG_FILTER\" found from $FROM_DATE to $TO_DATE."
  exit 0
fi

extract_people() {
  local file="$1"
  local in_people=false
  while IFS= read -r line; do
    if [[ "$line" == "## People" ]]; then
      in_people=true
      continue
    fi
    if $in_people; then
      if [[ "$line" =~ ^## ]]; then
        break
      fi
      if [[ "$line" =~ ^-\ (.+) ]]; then
        echo "${BASH_REMATCH[1]}" | sed 's/^- //'
      fi
    fi
  done < "$file"
}

extract_summary() {
  local file="$1"
  grep -A1 "^## Summary" "$file" 2>/dev/null | tail -1
}

extract_title() {
  local file="$1"
  head -1 "$file" 2>/dev/null | sed 's/^# [0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}: //'
}

# Collect tags
declare -A TAG_COUNTS
for entry in "${ENTRIES[@]}"; do
  file=$(echo "$entry" | cut -d'|' -f3)
  tags=$(extract_tags "$file")
  if [ -n "$tags" ]; then
    IFS=',' read -ra tag_arr <<< "$tags"
    for tag in "${tag_arr[@]}"; do
      tag=$(echo "$tag" | sed 's/^ *//;s/ *$//')
      if [ -n "$tag" ]; then
        TAG_COUNTS["$tag"]=$(( ${TAG_COUNTS["$tag"]:-0} + 1 ))
      fi
    done
  fi
done

# Collect people
declare -A PEOPLE_COUNTS
for entry in "${ENTRIES[@]}"; do
  file=$(echo "$entry" | cut -d'|' -f3)
  while IFS= read -r person; do
    if [ -n "$person" ]; then
      PEOPLE_COUNTS["$person"]=$(( ${PEOPLE_COUNTS["$person"]:-0} + 1 ))
    fi
  done < <(extract_people "$file")
done

# ---- Render output ----

render_bar() {
  local count=$1
  local max=$2
  local width=10
  if [ "$max" -eq 0 ]; then
    return
  fi
  local filled=$(( count * width / max ))
  if [ "$filled" -eq 0 ] && [ "$count" -gt 0 ]; then
    filled=1
  fi
  printf "%-*s" "$filled" "" | tr ' ' '█'
}

TOTAL_ENTRIES=${#ENTRIES[@]}

# Build tag table
TAG_ROWS=""
if [ ${#TAG_COUNTS[@]} -gt 0 ]; then
  # Find max count for bar scaling
  MAX_TAG=0
  for c in "${TAG_COUNTS[@]}"; do
    [ "$c" -gt "$MAX_TAG" ] && MAX_TAG=$c
  done
  # Sort tags by count descending
  TAG_SORTED=""
  for tag in "${!TAG_COUNTS[@]}"; do
    TAG_SORTED+="${TAG_COUNTS[$tag]}|$tag"$'\n'
  done
  TAG_SORTED=$(echo "$TAG_SORTED" | sort -t'|' -k1 -rn | head -10)

  while IFS= read -r line; do
    [ -z "$line" ] && continue
    count=$(echo "$line" | cut -d'|' -f1)
    tag=$(echo "$line" | cut -d'|' -f2-)
    bar=$(render_bar "$count" "$MAX_TAG")
    TAG_ROWS+=$(printf "  %-6s %s %s\n" "$tag" "$bar" "$count")
    TAG_ROWS+=$'\n'
  done <<< "$TAG_SORTED"
fi

# Build timeline
TIMELINE=""
for entry in "${ENTRIES[@]}"; do
  date_f=$(echo "$entry" | cut -d'|' -f1)
  basename_f=$(echo "$entry" | cut -d'|' -f2)
  file_f=$(echo "$entry" | cut -d'|' -f3-)
  title=$(extract_title "$file_f")
  summary=$(extract_summary "$file_f")
  short_date="${date_f:5}"  # MM-DD
  TIMELINE+=$(printf "  %s  — %s" "$short_date" "$title")$'\n'
  if [ -n "$summary" ]; then
    TIMELINE+=$(printf "       %s" "$summary")$'\n'
  fi
  TIMELINE+=$'\n'
done

# Build people summary
PEOPLE_TEXT=""
PEOPLE_SORTED=""
for person in "${!PEOPLE_COUNTS[@]}"; do
  PEOPLE_SORTED+="${PEOPLE_COUNTS[$person]}|$person"$'\n'
done
PEOPLE_SORTED=$(echo "$PEOPLE_SORTED" | sort -t'|' -k1 -rn)
while IFS= read -r line; do
  [ -z "$line" ] && continue
  count=$(echo "$line" | cut -d'|' -f1)
  person=$(echo "$line" | cut -d'|' -f2-)
  if [ -z "$PEOPLE_TEXT" ]; then
    PEOPLE_TEXT="$person ($count)"
  else
    PEOPLE_TEXT+=", $person ($count)"
  fi
done <<< "$PEOPLE_SORTED"
if [ -z "$PEOPLE_TEXT" ]; then
  PEOPLE_TEXT="None"
fi

TODAY=$(date "+%Y-%m-%d")

OUTPUT="━━━ Summary: ${FROM_DATE} → ${TO_DATE} ━━━"
if [ -n "$TAG_FILTER" ]; then
  OUTPUT+=" (tag: ${TAG_FILTER})"
fi
OUTPUT+=$'\n\nEntries: '"${TOTAL_ENTRIES}"$'\n\nTags:\n'"${TAG_ROWS}"$'\nTimeline:\n'"${TIMELINE}People: ${PEOPLE_TEXT}"$'\n'

# ---- Output ----

if [ "$SAVE_MODE" = true ]; then
  SLUG="summary-${FROM_DATE}-to-${TO_DATE}"
  YEAR="${FROM_DATE:0:4}"
  DIR="${JOURNAL_DIR}/${YEAR}"
  mkdir -p "$DIR"

  SUMMARY_TITLE="Summary: ${FROM_DATE} to ${TO_DATE}"

  cat > "${DIR}/${FROM_DATE:5:2}-${FROM_DATE:8:2}-summary-${FROM_DATE}-to-${TO_DATE}.md" << ENTRY
# ${TODAY}: ${SUMMARY_TITLE}

## Tags
summary

## Summary
Generated summary covering ${TOTAL_ENTRIES} entries from ${FROM_DATE} to ${TO_DATE}.

## Details

### Overview
- **Period:** ${FROM_DATE} → ${TO_DATE}
- **Entries:** ${TOTAL_ENTRIES}
- **Tags:** $(IFS=, ; echo "${!TAG_COUNTS[*]}" | tr ' ' ', ')

### Tag Frequency
| Tag | Count |
|-----|-------|
$(for tag in $(echo "$TAG_SORTED"); do
  count=$(echo "$tag" | cut -d'|' -f1)
  t=$(echo "$tag" | cut -d'|' -f2-)
  echo "| $t | $count |"
done)

### Entries
$(for entry in "${ENTRIES[@]}"; do
  date_f=$(echo "$entry" | cut -d'|' -f1)
  file_f=$(echo "$entry" | cut -d'|' -f3-)
  title=$(extract_title "$file_f")
  echo "- **${date_f}** — ${title}"
done)

## People
${PEOPLE_TEXT}

## Linked
ENTRY

  ENTRY_FILE="${YEAR}/${FROM_DATE:5:2}-${FROM_DATE:8:2}-summary-${FROM_DATE}-to-${TO_DATE}.md"
  echo "Summary saved: ${JOURNAL_DIR}/${ENTRY_FILE}"
else
  echo "$OUTPUT"
fi
