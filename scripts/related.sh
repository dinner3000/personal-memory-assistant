#!/usr/bin/env bash
#
# related.sh — Find entries related to a given journal entry
#
# Finds other entries that share tags, people, or keywords.
# Relationship scoring: tag match = 2 points, person match = 2 points,
# keyword match = 1 point.
#
# Usage:
#   ./scripts/related.sh "04-28-learning-rust"    # Match by filename fragment
#   ./scripts/related.sh journal/2026/04-28-learning-rust.md  # Full path
#   ./scripts/related.sh "Learning Rust"          # Match by title
#
# Options:
#   -t          Show relationship type breakdown (tags/people/keywords per entry)
#   -n N        Show top N results (default: 10)
#   -h          Show this help
#
#   JOURNAL_PATH (defaults to $HERMES_HOME/journal)
#

set -euo pipefail

HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
JOURNAL_DIR="${JOURNAL_PATH:-$HERMES_HOME/journal}"

if [ ! -d "$JOURNAL_DIR" ]; then
  echo "Error: journal directory not found at $JOURNAL_DIR"
  exit 1
fi

SHOW_BREAKDOWN=false
TOP_N=10

usage() {
  sed -n '2,17p' "$0" | sed 's/^# //;s/^#$//'
  exit 0
}

while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help) usage ;;
    -t) SHOW_BREAKDOWN=true; shift ;;
    -n) TOP_N="$2"; shift 2 ;;
    *) break ;;
  esac
done

if [ $# -eq 0 ]; then
  echo "Error: provide a filename fragment or title to find related entries."
  echo "Usage: $0 [-t] \"filename or title\""
  exit 1
fi

QUERY="$*"

# ---- Find the target file ----

TARGET_FILE=""

# Try exact filename match
if [ -f "$JOURNAL_DIR/${QUERY}" ]; then
  TARGET_FILE="$JOURNAL_DIR/${QUERY}"
elif [ -f "$QUERY" ]; then
  TARGET_FILE="$QUERY"
else
  # Search by filename fragment or title
  MATCHES=$(find "$JOURNAL_DIR" -type f -name "*.md" 2>/dev/null | while IFS= read -r f; do
    basename=$(basename "$f" .md)
    title=$(head -1 "$f" 2>/dev/null | sed 's/^# [0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}: //' | tr '[:upper:]' '[:lower:]')
    query_lc=$(echo "$QUERY" | tr '[:upper:]' '[:lower:]')
    if echo "$basename" | grep -qi "$query_lc" 2>/dev/null; then
      echo "$f"
    elif echo "$title" | grep -qi "$query_lc" 2>/dev/null; then
      echo "$f"
    fi
  done | head -1)

  if [ -z "$MATCHES" ]; then
    echo "No entry found matching: $QUERY"
    echo "Try a filename fragment like \"04-28-learning-rust\" or a partial title."
    exit 1
  fi
  TARGET_FILE="$MATCHES"
fi

# ---- Extract information from the target entry ----

extract_tags() {
  local file="$1"
  grep -A1 "^## Tags" "$file" 2>/dev/null | tail -1
}

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

extract_title() {
  local file="$1"
  head -1 "$file" 2>/dev/null | sed 's/^# [0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}: //'
}

extract_date() {
  local file="$1"
  head -1 "$file" 2>/dev/null | sed -n 's/^# \([0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}\):.*/\1/p'
}

# Get target info
TARGET_TAGS=$(extract_tags "$TARGET_FILE")
TARGET_TITLE=$(extract_title "$TARGET_FILE")
TARGET_DATE=$(extract_date "$TARGET_FILE")
TARGET_BASE=$(basename "$TARGET_FILE" .md)

# Build list of target tags (lowercase, trimmed)
TARGET_TAG_LIST=()
if [ -n "$TARGET_TAGS" ]; then
  IFS=',' read -ra raw_tags <<< "$TARGET_TAGS"
  for tag in "${raw_tags[@]}"; do
    tag=$(echo "$tag" | sed 's/^ *//;s/ *$//' | tr '[:upper:]' '[:lower:]')
    [ -n "$tag" ] && TARGET_TAG_LIST+=("$tag")
  done
fi

# Build list of target people
TARGET_PEOPLE_LIST=()
while IFS= read -r person; do
  person=$(echo "$person" | sed 's/^ *//;s/ *$//')
  [ -n "$person" ] && TARGET_PEOPLE_LIST+=("$person")
done < <(extract_people "$TARGET_FILE")

# Build list of target keywords (from title, excluding common words)
STOP_WORDS="a an the in on at to for of and or with from by is are was were be been have has had do does did will would could should may might about into through during before after above below between out off over under again further then once here there when where why how all each every both few more most other some such no nor not only own same so than too very just because as until while"
get_keywords() {
  local title="$1"
  echo "$title" \
    | tr '[:upper:]' '[:lower:]' \
    | sed 's/[^a-z0-9 ]/ /g' \
    | tr ' ' '\n' \
    | grep -v '^$' \
    | grep -v -F -w -f <(echo "$STOP_WORDS" | tr ' ' '\n') \
    | sort -u
}

TARGET_KEYWORDS=()
while IFS= read -r kw; do
  [ -n "$kw" ] && TARGET_KEYWORDS+=("$kw")
done < <(get_keywords "$TARGET_TITLE")

# ---- Scan all other entries for relationships ----

SCORES=()   # file|score|shared_tags|shared_people|shared_keywords

while IFS= read -r -d '' file; do
  [ "$file" = "$TARGET_FILE" ] && continue

  base=$(basename "$file" .md)
  title=$(extract_title "$file")
  entry_date=$(extract_date "$file")

  # Shared tags
  shared_tags=""
  tags=$(extract_tags "$file")
  if [ -n "$tags" ]; then
    IFS=',' read -ra entry_tags <<< "$tags"
    for tag in "${entry_tags[@]}"; do
      tag=$(echo "$tag" | sed 's/^ *//;s/ *$//' | tr '[:upper:]' '[:lower:]')
      for ttag in "${TARGET_TAG_LIST[@]}"; do
        if [ "$tag" = "$ttag" ]; then
          if [ -z "$shared_tags" ]; then
            shared_tags="$tag"
          else
            shared_tags+=", $tag"
          fi
          break
        fi
      done
    done
  fi

  # Shared people
  shared_people=""
  if [ ${#TARGET_PEOPLE_LIST[@]} -gt 0 ]; then
    people=$(extract_people "$file")
    if [ -n "$people" ]; then
      while IFS= read -r person; do
        person=$(echo "$person" | sed 's/^ *//;s/ *$//')
        [ -z "$person" ] && continue
        for tperson in "${TARGET_PEOPLE_LIST[@]}"; do
          if echo "$person" | grep -qi "$tperson" 2>/dev/null; then
            if [ -z "$shared_people" ]; then
              shared_people="$tperson"
            else
              shared_people+=", $tperson"
            fi
            break
          fi
        done
      done < <(extract_people "$file")
    fi
  fi

  # Shared keywords
  shared_keywords=""
  entry_lc=$(echo "$title" | tr '[:upper:]' '[:lower:]')
  for kw in "${TARGET_KEYWORDS[@]}"; do
    if echo "$entry_lc" | grep -q "\b${kw}\b"; then
      if [ -z "$shared_keywords" ]; then
        shared_keywords="$kw"
      else
        shared_keywords+=", $kw"
      fi
    fi
  done

  # Score
  score=0
  tag_count=0
  if [ -n "$shared_tags" ]; then
    tag_count=$(echo "$shared_tags" | tr ',' '\n' | wc -l | tr -d ' ')
    score=$((score + tag_count * 2))
  fi
  people_count=0
  if [ -n "$shared_people" ]; then
    people_count=$(echo "$shared_people" | tr ',' '\n' | wc -l | tr -d ' ')
    score=$((score + people_count * 2))
  fi
  kw_count=0
  if [ -n "$shared_keywords" ]; then
    kw_count=$(echo "$shared_keywords" | tr ',' '\n' | wc -l | tr -d ' ')
    score=$((score + kw_count * 1))
  fi

  if [ "$score" -gt 0 ] || [ -n "$shared_tags" ] || [ -n "$shared_people" ]; then
    SCORES+=("$score|$entry_date|$title|$shared_tags|$shared_people|$shared_keywords")
  fi
done < <(find "$JOURNAL_DIR" -type f -name "*.md" -print0 2>/dev/null)

# ---- Render ----

if [ ${#SCORES[@]} -eq 0 ]; then
  echo "No related entries found for \"$TARGET_TITLE\"."
  exit 0
fi

# Sort by score descending
IFS=$'\n' SCORES=($(sort -t'|' -k1 -rn <<<"${SCORES[*]}")); unset IFS

echo "━━━ Related to: ${TARGET_TITLE} (${TARGET_DATE}) ━━━"
echo ""

DISPLAY_COUNT=$TOP_N
[ "$DISPLAY_COUNT" -gt ${#SCORES[@]} ] && DISPLAY_COUNT=${#SCORES[@]}

for ((i=0; i<DISPLAY_COUNT; i++)); do
  IFS='|' read -r score date title tags people keywords <<< "${SCORES[$i]}"

  if [ "$SHOW_BREAKDOWN" = true ]; then
    echo "  $((i+1)). \"${title}\"  — ${date}  [score: ${score}]"
    [ -n "$tags" ]     && echo "     Tags: ${tags}"
    [ -n "$people" ]   && echo "     People: ${people}"
    [ -n "$keywords" ] && echo "     Keywords: ${keywords}"
    echo ""
  else
    echo "  $((i+1)). \"${title}\"  — ${date}  [${score}]"
  fi
done

if [ "$SHOW_BREAKDOWN" = false ] && [ "$DISPLAY_COUNT" -lt ${#SCORES[@]} ]; then
  echo "  ... and $(( ${#SCORES[@]} - DISPLAY_COUNT )) more (use -n to show more)"
fi
