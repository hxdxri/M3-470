#!/usr/bin/env bash
# run_full_pipeline.sh — Full CloneWorks pipeline in one session
# Compiles TXL grammars, Java, then runs cwbuild + cwdetect + cwformat + eval
set -euo pipefail

CW_DIR="/workspace/tools/cloneworks_artifact"
LOG_DIR="/workspace/evidence/logs"
mkdir -p "$LOG_DIR"

echo "=== Step 1: Compile TXL grammars ==="
cd "$CW_DIR/txl"
make clean 2>/dev/null || true
make 2>&1 | tail -5
GRAMMAR_COUNT=$(ls *.x 2>/dev/null | wc -l)
echo "TXL grammars compiled: $GRAMMAR_COUNT files"
cd "$CW_DIR"

echo ""
echo "=== Step 2: Compile Java sources ==="
INSTALL_DIR="."
LIBS="${INSTALL_DIR}/bin/"
LIBS="${LIBS}:${INSTALL_DIR}/libs/commons-lang3-3.4/commons-lang3-3.4.jar"
LIBS="${LIBS}:${INSTALL_DIR}/libs/commons-exec-1.3/commons-exec-1.3.jar"
LIBS="${LIBS}:${INSTALL_DIR}/libs/commons-cli-1.3.1/commons-cli-1.3.1.jar"
LIBS="${LIBS}:${INSTALL_DIR}/libs/commons-io-2.4/commons-io-2.4.jar"
rm -rf bin/
mkdir -p bin/
find src/ -name "*.java" > sources
javac -encoding UTF-8 -d bin/ -cp "$LIBS" @sources 2>&1 | tail -5 || true
rm -f sources
echo "Java compilation done"

echo ""
echo "=== Step 3: cwbuild on BigCloneBench subset ==="
SRC_ROOT="/workspace/data/bigclonebench_subset/src"
CWBUILD_OUT="/workspace/out/cwbuild"
rm -rf "$CWBUILD_OUT"
mkdir -p "$CWBUILD_OUT"

START_TIME=$(date +%s)
./cwbuild -i "$SRC_ROOT" \
          -f "$CWBUILD_OUT/bigclonebench.files" \
          -b "$CWBUILD_OUT/bigclonebench.fragments" \
          -l java -g function \
          -c type3token 2>&1 | grep -v "Failed for file" | tee "$LOG_DIR/cwbuild.log"
END_TIME=$(date +%s)
echo ""
echo "cwbuild completed in $((END_TIME - START_TIME))s"

FILE_COUNT=$(wc -l < "$CWBUILD_OUT/bigclonebench.files")
FRAG_COUNT=$(grep -vc "^#" "$CWBUILD_OUT/bigclonebench.fragments" 2>/dev/null || echo "0")
echo "Files indexed: $FILE_COUNT"
echo "Fragment entries: $FRAG_COUNT"

if [ "$FRAG_COUNT" -eq 0 ] || [ "$FRAG_COUNT" = "0" ]; then
    echo "ERROR: No fragments extracted. Cannot continue."
    exit 1
fi

echo ""
echo "=== Step 4: cwdetect ==="
CWDETECT_OUT="/workspace/out/cwdetect"
rm -rf "$CWDETECT_OUT"
mkdir -p "$CWDETECT_OUT"

SIMILARITY="${SIMILARITY:-0.7}"
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
