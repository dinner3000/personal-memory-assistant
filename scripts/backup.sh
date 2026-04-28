#!/usr/bin/env bash
#
# backup.sh — Archive the journal to a tar.gz file
#
# Usage:
#   ./scripts/backup.sh                          # Backup to default location
#   ./scripts/backup.sh /path/to/backup.tar.gz   # Custom output path
#
# Environment: JOURNAL_PATH (defaults to ./journal)
#

set -euo pipefail

JOURNAL_DIR="${JOURNAL_PATH:-$(dirname "$0")/../journal}"
PROJECT_ROOT="$(dirname "$0")/.."

if [ $# -ge 1 ]; then
  OUTPUT="$1"
else
  DATE=$(date "+%Y%m%d-%H%M%S")
  OUTPUT="${PROJECT_ROOT}/backup/journal-${DATE}.tar.gz"
fi

OUTPUT_DIR=$(dirname "$OUTPUT")
mkdir -p "$OUTPUT_DIR"

echo "Backing up journal..."
echo "  Source: $JOURNAL_DIR"
echo "  Output: $OUTPUT"

tar -czf "$OUTPUT" -C "$(dirname "$JOURNAL_DIR")" "$(basename "$JOURNAL_DIR")"

echo "Done. Size: $(du -h "$OUTPUT" | cut -f1)"
