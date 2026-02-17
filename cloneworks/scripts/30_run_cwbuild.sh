#!/usr/bin/env bash
# 30_run_cwbuild.sh — Run CloneWorks input builder on a source directory
#
# Usage:
#   ./scripts/30_run_cwbuild.sh <src_root> <output_dir> <config_name>
#
# Example:
#   ./scripts/30_run_cwbuild.sh data/bigclonebench_subset/src out/cwbuild type3token
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CW_DIR="${ROOT_DIR}/tools/cloneworks_artifact"
LOG_DIR="${ROOT_DIR}/evidence/logs"
LOG_FILE="${LOG_DIR}/cwbuild.log"

SRC_ROOT="${1:?Usage: $0 <src_root> <output_dir> <config_name>}"
OUTPUT_DIR="${2:?Usage: $0 <src_root> <output_dir> <config_name>}"
CONFIG_NAME="${3:?Usage: $0 <src_root> <output_dir> <config_name>}"

mkdir -p "$OUTPUT_DIR" "$LOG_DIR"

# Resolve to absolute paths
SRC_ROOT="$(cd "$ROOT_DIR" && realpath "$SRC_ROOT")"
OUTPUT_DIR="$(cd "$ROOT_DIR" && realpath "$OUTPUT_DIR")"

echo "=== Running cwbuild ===" | tee "$LOG_FILE"
echo "Date        : $(date -u)" | tee -a "$LOG_FILE"
echo "Source root : $SRC_ROOT" | tee -a "$LOG_FILE"
echo "Output dir  : $OUTPUT_DIR" | tee -a "$LOG_FILE"
echo "Config      : $CONFIG_NAME" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Check if config exists in CloneWorks config/ directory
# If the user passed a path to our config/ dir, copy it
if [ -f "${ROOT_DIR}/config/${CONFIG_NAME}" ]; then
    echo "Copying config to CloneWorks config dir..." | tee -a "$LOG_FILE"
    cp "${ROOT_DIR}/config/${CONFIG_NAME}" "${CW_DIR}/config/${CONFIG_NAME}"
elif [ -f "${CW_DIR}/config/${CONFIG_NAME}" ]; then
    echo "Config found in CloneWorks config dir." | tee -a "$LOG_FILE"
else
    echo "ERROR: Config '${CONFIG_NAME}' not found in ${ROOT_DIR}/config/ or ${CW_DIR}/config/" | tee -a "$LOG_FILE"
    exit 1
fi

cd "$CW_DIR"

FILES_OUT="${OUTPUT_DIR}/bigclonebench.files"
FRAGMENTS_OUT="${OUTPUT_DIR}/bigclonebench.fragments"

echo "Running: ./cwbuild -i $SRC_ROOT -f $FILES_OUT -b $FRAGMENTS_OUT -l java -g function -c $CONFIG_NAME" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

START_TIME=$(date +%s)

./cwbuild -i "$SRC_ROOT" \
          -f "$FILES_OUT" \
          -b "$FRAGMENTS_OUT" \
          -l java -g function \
          -c "$CONFIG_NAME" 2>&1 | tee -a "$LOG_FILE" || {
    echo "" | tee -a "$LOG_FILE"
    echo "ERROR: cwbuild failed. See log above." | tee -a "$LOG_FILE"
    exit 1
}

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))

echo "" | tee -a "$LOG_FILE"
echo "cwbuild completed in ${ELAPSED}s" | tee -a "$LOG_FILE"
echo "Files output   : $FILES_OUT" | tee -a "$LOG_FILE"
echo "Fragments output: $FRAGMENTS_OUT" | tee -a "$LOG_FILE"

if [ -f "$FILES_OUT" ]; then
    FILE_COUNT=$(wc -l < "$FILES_OUT")
    echo "Source files indexed: $FILE_COUNT" | tee -a "$LOG_FILE"
fi
if [ -f "$FRAGMENTS_OUT" ]; then
    FRAG_COUNT=$(wc -l < "$FRAGMENTS_OUT")
    echo "Fragments extracted: $FRAG_COUNT" | tee -a "$LOG_FILE"
fi

echo "=== Done ===" | tee -a "$LOG_FILE"
