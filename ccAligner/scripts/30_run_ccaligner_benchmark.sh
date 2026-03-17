#!/usr/bin/env bash
# 30_run_ccaligner_benchmark.sh — Run CCAligner on prepared Java source subset
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ART_DIR="${ROOT_DIR}/tools/ccaligner_artifact"
SRC_ROOT="${1:-${ROOT_DIR}/data/bigclonebench_subset/src}"
OUT_DIR="${2:-${ROOT_DIR}/out/ccaligner}"
LOG_DIR="${ROOT_DIR}/evidence/logs"
LOG_FILE="${LOG_DIR}/ccaligner_benchmark.log"

THREADS="${THREADS:-8}"
WINDOW_SIZE="${WINDOW_SIZE:-6}"
EDIT_DISTANCE="${EDIT_DISTANCE:-1}"
SIMILARITY="${SIMILARITY:-0.6}"

mkdir -p "$OUT_DIR" "$LOG_DIR"

{
    echo "=== CCAligner Benchmark Run ==="
    date -u
    echo "artifact=$ART_DIR"
    echo "src_root=$SRC_ROOT"
    echo "out_dir=$OUT_DIR"
    echo "threads=$THREADS window=$WINDOW_SIZE edit=$EDIT_DISTANCE similarity=$SIMILARITY"

    if [ ! -d "$ART_DIR" ]; then
        echo "ERROR: artifact dir missing: $ART_DIR"
        exit 1
    fi
    if [ ! -d "$SRC_ROOT" ]; then
        echo "ERROR: source dir missing: $SRC_ROOT"
        exit 1
    fi

    cd "$ART_DIR"
    chmod +x extract parser tokenize detect detect2 co1 || true
    chmod +x txl/*.x || true

    cd lexical
    make clean >/dev/null 2>&1 || true
    make
    cd ..

    mkdir -p input output
    rm -rf input/* output/*
    find token -type f -delete || true
    rm -f function.file tokenline_num clones

    ./extract ./txl java functions "$SRC_ROOT" ./input "$THREADS"
    ./parser ./input ./ "$THREADS"
    ./tokenize ./function.file ./token ./ "$THREADS"
    ./detect ./token ./output ./function.file "$WINDOW_SIZE" "$EDIT_DISTANCE" "$SIMILARITY"
    ./co1 ./output ./

    cp -f function.file "$OUT_DIR/function.file"
    cp -f tokenline_num "$OUT_DIR/tokenline_num" || true
    cp -f clones "$OUT_DIR/clones.csv" || true
    mkdir -p "$OUT_DIR/output_shards"
    cp -f output/* "$OUT_DIR/output_shards/" || true

    echo "function_count=$(wc -l < function.file || echo 0)"
    echo "clone_count=$(wc -l < clones || echo 0)"
    echo "=== Benchmark Run Complete ==="
} > "$LOG_FILE" 2>&1

echo "Benchmark log written to $LOG_FILE"
