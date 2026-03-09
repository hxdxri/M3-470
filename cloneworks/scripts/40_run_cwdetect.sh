#!/usr/bin/env bash
# 40_run_cwdetect.sh — Run CloneWorks clone detector
#
# Usage:
#   ./scripts/40_run_cwdetect.sh <cwbuild_output_dir> <output_dir> <config_file>
#
# Example:
#   ./scripts/40_run_cwdetect.sh out/cwbuild out/cwdetect config/cwdetect.conf
#
# The config_file is unused by cwdetect (it uses CLI args), but is accepted
# for consistency with the system prompt. Similarity threshold defaults to 0.7.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CW_DIR="${ROOT_DIR}/tools/cloneworks_artifact"
LOG_DIR="${ROOT_DIR}/evidence/logs"
LOG_FILE="${LOG_DIR}/cwdetect.log"

CWBUILD_DIR="${1:?Usage: $0 <cwbuild_output_dir> <output_dir> <config_file>}"
OUTPUT_DIR="${2:?Usage: $0 <cwbuild_output_dir> <output_dir> <config_file>}"
CONFIG_FILE="${3:?Usage: $0 <cwbuild_output_dir> <output_dir> <config_file>}"

# Similarity threshold — paper recommends 0.7 for Type-3
SIMILARITY="${SIMILARITY:-0.7}"

mkdir -p "$OUTPUT_DIR" "$LOG_DIR"

# Resolve to absolute paths
CWBUILD_DIR="$(cd "$ROOT_DIR" && realpath "$CWBUILD_DIR")"
OUTPUT_DIR="$(cd "$ROOT_DIR" && realpath "$OUTPUT_DIR")"

FRAGMENTS_IN="${CWBUILD_DIR}/bigclonebench.fragments"
CLONES_OUT="${OUTPUT_DIR}/bigclonebench.clones"

echo "=== Running cwdetect ===" | tee "$LOG_FILE"
echo "Date           : $(date -u)" | tee -a "$LOG_FILE"
echo "Fragments in   : $FRAGMENTS_IN" | tee -a "$LOG_FILE"
echo "Clones out     : $CLONES_OUT" | tee -a "$LOG_FILE"
echo "Similarity     : $SIMILARITY" | tee -a "$LOG_FILE"
echo "Config (info)  : $CONFIG_FILE" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

if [ ! -f "$FRAGMENTS_IN" ]; then
    echo "ERROR: Fragments file not found: $FRAGMENTS_IN" | tee -a "$LOG_FILE"
    echo "Run scripts/30_run_cwbuild.sh first." | tee -a "$LOG_FILE"
    exit 1
fi

cd "$CW_DIR"

echo "Running: ./cwdetect -i $FRAGMENTS_IN -o $CLONES_OUT -s $SIMILARITY" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

START_TIME=$(date +%s)

./cwdetect -i "$FRAGMENTS_IN" \
           -o "$CLONES_OUT" \
           -s "$SIMILARITY" 2>&1 | tee -a "$LOG_FILE" || {
    echo "" | tee -a "$LOG_FILE"
    echo "ERROR: cwdetect failed. See log above." | tee -a "$LOG_FILE"
    exit 1
}

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))

echo "" | tee -a "$LOG_FILE"
echo "cwdetect completed in ${ELAPSED}s" | tee -a "$LOG_FILE"
echo "Output: $CLONES_OUT" | tee -a "$LOG_FILE"

if [ -f "$CLONES_OUT" ]; then
    CLONE_COUNT=$(wc -l < "$CLONES_OUT")
    echo "Clone pairs found: $CLONE_COUNT" | tee -a "$LOG_FILE"
fi

echo "=== Done ===" | tee -a "$LOG_FILE"
