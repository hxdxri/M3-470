#!/usr/bin/env bash
# run_full_pipeline.sh — Full CloneWorks pipeline in one session
# Compiles TXL grammars, Java, then runs cwbuild + cwdetect + cwformat + eval
# Designed to run inside the cloneworks:amd64 Docker container
set -uo pipefail

# ---- Auto-detect resources ----
TOTAL_MEM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
TOTAL_MEM_GB=$((TOTAL_MEM_KB / 1024 / 1024))
NPROC=$(nproc 2>/dev/null || echo 2)
# Give JVM ~70% of available RAM, minimum 2G
JVM_HEAP=$(( TOTAL_MEM_GB * 70 / 100 ))
[ "$JVM_HEAP" -lt 2 ] && JVM_HEAP=2
# Cap parallelism to nproc
PARALLEL_THREADS=${PARALLEL_THREADS:-$NPROC}
export JVM_HEAP PARALLEL_THREADS NPROC
echo "Detected resources: ${TOTAL_MEM_GB}G RAM, ${NPROC} CPUs → JVM heap ${JVM_HEAP}G, threads ${PARALLEL_THREADS}"

CW_DIR="/workspace/tools/cloneworks_artifact"
LOG_DIR="/workspace/evidence/logs"
mkdir -p "$LOG_DIR"

# ---- Step 1: TXL grammars ----
echo "=== Step 1: Compile TXL grammars ==="
cd "$CW_DIR/txl"
make clean 2>/dev/null || true
make 2>&1 | tail -5
GRAMMAR_COUNT=$(ls *.x 2>/dev/null | wc -l)
echo "TXL grammars compiled: $GRAMMAR_COUNT files"
if [ "$GRAMMAR_COUNT" -lt 10 ]; then
    echo "ERROR: Too few TXL grammars compiled ($GRAMMAR_COUNT). Aborting."
    exit 1
fi
cd "$CW_DIR"

# ---- Step 2: Compile Java sources (always recompile to match container JDK) ----
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
java -version 2>&1 || true

# Patch cwbuild/cwdetect to use detected memory
sed -i "s/^MEM=.*/MEM=${JVM_HEAP}G/" "$CW_DIR/cwbuild"
sed -i "s/^TC_MEMORY=.*/TC_MEMORY=${JVM_HEAP}G/" "$CW_DIR/cwdetect"

# ---- Step 2.5: Prepare BigCloneBench subset (download + materialize) ----
echo ""
echo "=== Step 2.5: Prepare BigCloneBench subset ==="
if [ ! -d /workspace/data/bigclonebench_subset/src ]; then
    python3 /workspace/scripts/10_prepare_bigclonebench_subset.py \
        --n 2000 --seed 42 \
        --output-dir /workspace/data/bigclonebench_subset \
        --evidence-dir "$LOG_DIR"
else
    echo "BigCloneBench subset already exists, skipping download."
fi

# ---- Step 3: cwbuild with timeout ----
echo ""
echo "=== Step 3: cwbuild on BigCloneBench subset ==="
SRC_ROOT="/workspace/data/bigclonebench_subset/src"
CWBUILD_OUT="/workspace/out/cwbuild"
rm -rf "$CWBUILD_OUT"
mkdir -p "$CWBUILD_OUT"

CWBUILD_TIMEOUT="${CWBUILD_TIMEOUT:-3600}"  # 60 minutes default
echo "Timeout: ${CWBUILD_TIMEOUT}s"
echo "Source : $SRC_ROOT"
echo "Output : $CWBUILD_OUT"

START_TIME=$(date +%s)
timeout --signal=TERM --kill-after=30 "$CWBUILD_TIMEOUT" \
    ./cwbuild -i "$SRC_ROOT" \
              -f "$CWBUILD_OUT/bigclonebench.files" \
              -b "$CWBUILD_OUT/bigclonebench.fragments" \
              -l java -g file \
              -c type3token > "$LOG_DIR/cwbuild.log" 2>&1
CWBUILD_EXIT=$?
grep -v "Failed for file" "$LOG_DIR/cwbuild.log"
END_TIME=$(date +%s)
echo ""
echo "cwbuild exited with code $CWBUILD_EXIT in $((END_TIME - START_TIME))s"

# Count fragments (lines not starting with #)
FRAG_COUNT=$(grep -c "^[0-9]" "$CWBUILD_OUT/bigclonebench.fragments" 2>/dev/null | tr -d '[:space:]' || echo "0")
FILE_COUNT=$(wc -l < "$CWBUILD_OUT/bigclonebench.files" 2>/dev/null | tr -d ' ' || echo "0")
echo "Files indexed: $FILE_COUNT"
echo "Fragments extracted: $FRAG_COUNT"

if [ "$FRAG_COUNT" -lt 1 ]; then
    echo "ERROR: No fragments extracted. Cannot continue."
    exit 1
fi

if [ "$CWBUILD_EXIT" -ne 0 ]; then
    echo "WARNING: cwbuild did not complete cleanly (timeout or error)."
    echo "         Continuing with $FRAG_COUNT partial fragments."
fi

# ---- Step 4: cwdetect ----
echo ""
echo "=== Step 4: cwdetect ==="
CWDETECT_OUT="/workspace/out/cwdetect"
rm -rf "$CWDETECT_OUT"
mkdir -p "$CWDETECT_OUT"

SIMILARITY="${SIMILARITY:-0.7}"
echo "Similarity threshold: $SIMILARITY"
START_TIME=$(date +%s)
time ./cwdetect -i "$CWBUILD_OUT/bigclonebench.fragments" \
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

# ---- Step 5: cwformat ----
echo ""
echo "=== Step 5: cwformat (post-processing) ==="
cd /workspace
bash scripts/50_run_cwformat.sh out/cwdetect out/cwformat out/cwbuild 2>&1

# ---- Step 6: Evaluation ----
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
echo "Results in results/ and out/eval/"
ls -la /workspace/results/ 2>/dev/null || true
ls -la /workspace/out/eval/ 2>/dev/null || true
