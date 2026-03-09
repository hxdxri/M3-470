#!/usr/bin/env bash
# 50_run_cwformat.sh — Convert CloneWorks output to evaluation-friendly format
#
# Usage:
#   ./scripts/50_run_cwformat.sh <cwdetect_output_dir> <output_dir>
#
# CloneWorks clone output format:  fileID1,startLine1,endLine1,fileID2,startLine2,endLine2
# This script converts it to a JSON-lines file mapping file paths to clone pairs
# using the fileids mapping from cwbuild.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CW_DIR="${ROOT_DIR}/tools/cloneworks_artifact"
LOG_DIR="${ROOT_DIR}/evidence/logs"
LOG_FILE="${LOG_DIR}/cwformat.log"

CWDETECT_DIR="${1:?Usage: $0 <cwdetect_output_dir> <output_dir>}"
OUTPUT_DIR="${2:?Usage: $0 <cwdetect_output_dir> <output_dir>}"

# Optional: path to cwbuild output dir to find fileids mapping
CWBUILD_DIR="${3:-out/cwbuild}"

mkdir -p "$OUTPUT_DIR" "$LOG_DIR"

# Resolve to absolute paths
CWDETECT_DIR="$(cd "$ROOT_DIR" && realpath "$CWDETECT_DIR")"
OUTPUT_DIR="$(cd "$ROOT_DIR" && realpath "$OUTPUT_DIR")"
CWBUILD_DIR="$(cd "$ROOT_DIR" && realpath "$CWBUILD_DIR")"

CLONES_IN="${CWDETECT_DIR}/bigclonebench.clones"
FILES_MAP="${CWBUILD_DIR}/bigclonebench.files"
FORMATTED_OUT="${OUTPUT_DIR}/clones_formatted.jsonl"
FORMATTED_CSV="${OUTPUT_DIR}/clones_formatted.csv"

echo "=== Running cwformat (post-processing) ===" | tee "$LOG_FILE"
echo "Date         : $(date -u)" | tee -a "$LOG_FILE"
echo "Clones in    : $CLONES_IN" | tee -a "$LOG_FILE"
echo "Files map    : $FILES_MAP" | tee -a "$LOG_FILE"
echo "Output dir   : $OUTPUT_DIR" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

if [ ! -f "$CLONES_IN" ]; then
    echo "ERROR: Clones file not found: $CLONES_IN" | tee -a "$LOG_FILE"
    echo "Run scripts/40_run_cwdetect.sh first." | tee -a "$LOG_FILE"
    exit 1
fi

if [ ! -f "$FILES_MAP" ]; then
    echo "ERROR: Files map not found: $FILES_MAP" | tee -a "$LOG_FILE"
    echo "Run scripts/30_run_cwbuild.sh first." | tee -a "$LOG_FILE"
    exit 1
fi

# ---- Convert using Python for reliability ----
python3 - "$FILES_MAP" "$CLONES_IN" "$FORMATTED_OUT" "$FORMATTED_CSV" <<'PYEOF'
import sys
import json
import os

files_map_path = sys.argv[1]
clones_path = sys.argv[2]
jsonl_out = sys.argv[3]
csv_out = sys.argv[4]

# Parse fileID -> filePath mapping
# CloneWorks fileids format: one line per file, "ID\tPATH" or "ID PATH"
fileid_map = {}
with open(files_map_path, "r") as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        parts = line.split("\t")
        if len(parts) < 2:
            parts = line.split(None, 1)
        if len(parts) >= 2:
            try:
                fid = int(parts[0])
                fpath = parts[1]
                fileid_map[fid] = fpath
            except ValueError:
                continue

print(f"Loaded {len(fileid_map)} file ID mappings")

# Parse clones: format is fileID1,startLine1,endLine1,fileID2,startLine2,endLine2
clone_pairs = []
with open(clones_path, "r") as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        parts = line.split(",")
        if len(parts) >= 6:
            try:
                fid1, sl1, el1, fid2, sl2, el2 = int(parts[0]), int(parts[1]), int(parts[2]), \
                                                   int(parts[3]), int(parts[4]), int(parts[5])
                path1 = fileid_map.get(fid1, f"unknown_{fid1}")
                path2 = fileid_map.get(fid2, f"unknown_{fid2}")
                clone_pairs.append({
                    "file1_id": fid1,
                    "file1_path": path1,
                    "file1_start": sl1,
                    "file1_end": el1,
                    "file2_id": fid2,
                    "file2_path": path2,
                    "file2_start": sl2,
                    "file2_end": el2,
                })
            except (ValueError, IndexError):
                continue

print(f"Parsed {len(clone_pairs)} clone pairs")

# Write JSONL
with open(jsonl_out, "w") as f:
    for cp in clone_pairs:
        f.write(json.dumps(cp) + "\n")

# Write CSV
with open(csv_out, "w") as f:
    f.write("file1_id,file1_path,file1_start,file1_end,file2_id,file2_path,file2_start,file2_end\n")
    for cp in clone_pairs:
        f.write(f"{cp['file1_id']},{cp['file1_path']},{cp['file1_start']},{cp['file1_end']},"
                f"{cp['file2_id']},{cp['file2_path']},{cp['file2_start']},{cp['file2_end']}\n")

print(f"Formatted output written to:")
print(f"  JSONL: {jsonl_out}")
print(f"  CSV:   {csv_out}")
PYEOF

echo "" | tee -a "$LOG_FILE"

if [ -f "$FORMATTED_OUT" ]; then
    PAIR_COUNT=$(wc -l < "$FORMATTED_OUT")
    echo "Formatted clone pairs: $PAIR_COUNT" | tee -a "$LOG_FILE"
else
    echo "WARNING: No formatted output produced." | tee -a "$LOG_FILE"
fi

echo "=== Done ===" | tee -a "$LOG_FILE"
