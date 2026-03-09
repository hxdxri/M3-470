#!/usr/bin/env bash
# run_remaining_pipeline.sh — cwdetect + cwformat + eval (cwbuild already done)
set -euo pipefail

CW_DIR="/workspace/tools/cloneworks_artifact"
LOG_DIR="/workspace/evidence/logs"
mkdir -p "$LOG_DIR"

echo "=== Checking cwbuild output ==="
CWBUILD_OUT="/workspace/out/cwbuild"
FRAG_COUNT=$(grep -c "^[0-9]" "$CWBUILD_OUT/bigclonebench.fragments" || echo "0")
FILE_COUNT=$(grep -vc "^#" "$CWBUILD_OUT/bigclonebench.files" || echo "0")
echo "Files indexed: $FILE_COUNT"
echo "Fragments extracted: $FRAG_COUNT"

if [ "$FRAG_COUNT" -lt 1 ]; then
    echo "ERROR: No fragments found. Cannot continue."
    exit 1
fi

echo ""
echo "=== Step 4: cwdetect ==="
cd "$CW_DIR"

# Compile Java if needed (volume mount, so bin/ may not exist)
if [ ! -d "bin" ] || [ -z "$(ls -A bin/ 2>/dev/null)" ]; then
    echo "Compiling Java sources..."
    INSTALL_DIR="."
    LIBS="${INSTALL_DIR}/bin/"
    LIBS="${LIBS}:${INSTALL_DIR}/libs/commons-lang3-3.4/commons-lang3-3.4.jar"
    LIBS="${LIBS}:${INSTALL_DIR}/libs/commons-exec-1.3/commons-exec-1.3.jar"
    LIBS="${LIBS}:${INSTALL_DIR}/libs/commons-cli-1.3.1/commons-cli-1.3.1.jar"
    LIBS="${LIBS}:${INSTALL_DIR}/libs/commons-io-2.4/commons-io-2.4.jar"
    rm -rf bin/; mkdir -p bin/
    find src/ -name "*.java" > sources
    javac -encoding UTF-8 -d bin/ -cp "$LIBS" @sources 2>&1 | tail -3 || true
    rm -f sources
    echo "Java compilation done"
fi

CWDETECT_OUT="/workspace/out/cwdetect"
rm -rf "$CWDETECT_OUT"
mkdir -p "$CWDETECT_OUT"

SIMILARITY="${SIMILARITY:-0.7}"
echo "Running cwdetect (similarity=$SIMILARITY)..."
START_TIME=$(date +%s)
./cwdetect -i "$CWBUILD_OUT/bigclonebench.fragments" \
           -o "$CWDETECT_OUT/bigclonebench.clones" \
           -s "$SIMILARITY" 2>&1 | tee "$LOG_DIR/cwdetect.log"
END_TIME=$(date +%s)
echo ""
echo "cwdetect completed in $((END_TIME - START_TIME))s"

if [ -f "$CWDETECT_OUT/bigclonebench.clones" ]; then
    CLONE_COUNT=$(wc -l < "$CWDETECT_OUT/bigclonebench.clones")
    echo "Clone pairs found: $CLONE_COUNT"
else
    echo "ERROR: No clones file produced."
    exit 1
fi

echo ""
echo "=== Step 5: cwformat (post-processing) ==="
cd /workspace
./scripts/50_run_cwformat.sh out/cwdetect out/cwformat out/cwbuild 2>&1

echo ""
echo "=== Step 6: Evaluation ==="
python3 scripts/60_eval_bigclonebench.py \
    --oracle data/bigclonebench_subset/oracle/oracle_pairs.jsonl \
    --clones out/cwformat/clones_formatted.jsonl \
    --filemap out/cwbuild/bigclonebench.files \
    --src-root data/bigclonebench_subset/src \
    --results-dir results \
    --eval-dir out/eval 2>&1

echo ""
echo "=== Pipeline Complete ==="
echo "Results in results/ and out/"
