#!/usr/bin/env bash
#
# monthly-digest.sh — Replaced by summary.sh
#
# This script is kept for backward compatibility.
# Use ./scripts/summary.sh -m [YYYY-MM] instead.
#

DIR="$(cd "$(dirname "$0")" && pwd)"
echo "Note: monthly-digest.sh has been replaced by summary.sh"
echo "Run: $DIR/summary.sh -m ${1:-}"
echo ""
exec "$DIR/summary.sh" -m "${1:-}"
