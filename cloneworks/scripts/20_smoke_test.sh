#!/usr/bin/env bash
# 20_smoke_test.sh — Verify CloneWorks binaries run correctly
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CW_DIR="${ROOT_DIR}/tools/cloneworks_artifact"
LOG_DIR="${ROOT_DIR}/evidence/logs"
LOG_FILE="${LOG_DIR}/smoke_test.log"

mkdir -p "$LOG_DIR"

echo "=== CloneWorks Smoke Test ===" | tee "$LOG_FILE"
echo "Date: $(date -u)" | tee -a "$LOG_FILE"
echo "CW_DIR: $CW_DIR" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# ---- Check artifact exists ----
if [ ! -d "$CW_DIR" ]; then
    echo "ERROR: CloneWorks artifact not found at $CW_DIR" | tee -a "$LOG_FILE"
    echo "Run scripts/01_fetch_artifact.sh first." | tee -a "$LOG_FILE"
    exit 1
fi

# ---- Check Java ----
echo "--- Java version ---" | tee -a "$LOG_FILE"
java -version 2>&1 | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# ---- Check TXL ----
echo "--- TXL check ---" | tee -a "$LOG_FILE"
if command -v txl &>/dev/null; then
    txl -version 2>&1 | tee -a "$LOG_FILE" || echo "txl -version returned non-zero" | tee -a "$LOG_FILE"
else
    echo "WARNING: txl not found on PATH. CloneWorks requires FreeTXL 10.6+." | tee -a "$LOG_FILE"
    echo "cwbuild will likely fail without TXL." | tee -a "$LOG_FILE"
fi
echo "" | tee -a "$LOG_FILE"

# ---- Build CloneWorks ----
echo "--- Building CloneWorks ---" | tee -a "$LOG_FILE"
cd "$CW_DIR"

# Try to build TXL grammars if txl is available
if command -v txl &>/dev/null && [ -d "txl" ] && [ -f "txl/Makefile" ]; then
    echo "Compiling TXL grammars..." | tee -a "$LOG_FILE"
    (cd txl && make clean && make) 2>&1 | tee -a "$LOG_FILE" || {
        echo "WARNING: TXL grammar compilation failed." | tee -a "$LOG_FILE"
    }
else
    echo "Skipping TXL grammar compilation (txl not available or no Makefile)." | tee -a "$LOG_FILE"
fi

# Compile Java sources
echo "Compiling Java sources..." | tee -a "$LOG_FILE"
INSTALL_DIR="."
LIBS="${INSTALL_DIR}/bin/"
LIBS="${LIBS}:${INSTALL_DIR}/libs/commons-lang3-3.4/commons-lang3-3.4.jar"
LIBS="${LIBS}:${INSTALL_DIR}/libs/commons-exec-1.3/commons-exec-1.3.jar"
LIBS="${LIBS}:${INSTALL_DIR}/libs/commons-cli-1.3.1/commons-cli-1.3.1.jar"
LIBS="${LIBS}:${INSTALL_DIR}/libs/commons-io-2.4/commons-io-2.4.jar"

rm -rf bin/
mkdir -p bin/
find src/ -name "*.java" > sources 2>/dev/null || true
if [ -s sources ]; then
    javac -encoding UTF-8 -d bin/ -cp "$LIBS" @sources 2>&1 | tee -a "$LOG_FILE" || {
        echo "ERROR: Java compilation failed." | tee -a "$LOG_FILE"
        rm -f sources
        exit 1
    }
    rm -f sources
    echo "Java compilation succeeded." | tee -a "$LOG_FILE"
else
    echo "ERROR: No Java sources found in src/." | tee -a "$LOG_FILE"
    rm -f sources
    exit 1
fi
echo "" | tee -a "$LOG_FILE"

# ---- Run cwbuild on example ----
echo "--- Running cwbuild on example/JHotDraw54b1/ ---" | tee -a "$LOG_FILE"
if [ -d "example/JHotDraw54b1" ]; then
    chmod +x cwbuild cwdetect cwformat 2>/dev/null || true

    # Determine which config to use (type3token exists in this repo)
    CONFIG="type3token"
    if [ -f "config/type3_conservative" ]; then
        CONFIG="type3_conservative"
    fi

    ./cwbuild -i example/JHotDraw54b1/ \
              -f example/JHotDraw_smoke.files \
              -b example/JHotDraw_smoke.fragments \
              -l java -g function \
              -c "$CONFIG" 2>&1 | tee -a "$LOG_FILE" || {
        echo "ERROR: cwbuild failed on JHotDraw example." | tee -a "$LOG_FILE"
        echo "This may be due to missing TXL. See log for details." | tee -a "$LOG_FILE"
        exit 1
    }
    echo "cwbuild succeeded on JHotDraw." | tee -a "$LOG_FILE"
else
    echo "WARNING: example/JHotDraw54b1/ not found, skipping cwbuild smoke test." | tee -a "$LOG_FILE"
fi
echo "" | tee -a "$LOG_FILE"

# ---- Run cwdetect on example output ----
echo "--- Running cwdetect on JHotDraw fragments ---" | tee -a "$LOG_FILE"
if [ -f "example/JHotDraw_smoke.fragments" ]; then
    ./cwdetect -i example/JHotDraw_smoke.fragments \
               -o example/JHotDraw_smoke.clones \
               -s 0.7 2>&1 | tee -a "$LOG_FILE" || {
        echo "ERROR: cwdetect failed on JHotDraw example." | tee -a "$LOG_FILE"
        exit 1
    }
    echo "cwdetect succeeded on JHotDraw." | tee -a "$LOG_FILE"

    CLONE_COUNT=$(wc -l < example/JHotDraw_smoke.clones 2>/dev/null || echo "0")
    echo "Clones found: $CLONE_COUNT" | tee -a "$LOG_FILE"
else
    echo "WARNING: No fragments file, skipping cwdetect smoke test." | tee -a "$LOG_FILE"
fi
echo "" | tee -a "$LOG_FILE"

# ---- Summary ----
echo "=== Smoke Test Summary ===" | tee -a "$LOG_FILE"
echo "Java compilation: PASS" | tee -a "$LOG_FILE"
if [ -f "example/JHotDraw_smoke.clones" ]; then
    echo "cwbuild:          PASS" | tee -a "$LOG_FILE"
    echo "cwdetect:         PASS" | tee -a "$LOG_FILE"
    echo "Overall:          PASS" | tee -a "$LOG_FILE"
else
    echo "cwbuild/cwdetect: INCOMPLETE (see log)" | tee -a "$LOG_FILE"
    echo "Overall:          PARTIAL" | tee -a "$LOG_FILE"
fi
echo "Log: $LOG_FILE" | tee -a "$LOG_FILE"
echo "=== Done ===" | tee -a "$LOG_FILE"
