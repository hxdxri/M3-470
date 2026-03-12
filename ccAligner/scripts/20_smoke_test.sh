#!/usr/bin/env bash
# 20_smoke_test.sh — Basic executable smoke test for CCAligner artifact
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ARTIFACT_DIR="${ROOT_DIR}/tools/ccaligner_artifact"
LOG_DIR="${ROOT_DIR}/evidence/logs"
WORK_DIR="${ROOT_DIR}/out/smoke"

mkdir -p "$LOG_DIR" "$WORK_DIR"
LOG_FILE="${LOG_DIR}/smoke_test.log"

{
    echo "=== CCAligner Smoke Test ==="
    date -u
    echo "root=$ROOT_DIR"
    echo "artifact=$ARTIFACT_DIR"

    if [ ! -d "$ARTIFACT_DIR" ]; then
        echo "Artifact missing. Run scripts/01_fetch_artifact.sh first."
        exit 1
    fi

    if [ "$(uname -s)" != "Linux" ]; then
        echo "ERROR: CCAligner artifact and toolchain are Linux-oriented."
        echo "Run this script in Docker (see README.md)."
        exit 2
    fi

    cd "$ARTIFACT_DIR"

    # Tool prerequisites from artifact README.
    command -v g++ >/dev/null || echo "WARNING: g++ not found"
    command -v flex >/dev/null || echo "WARNING: flex not found"

    # Build lexical helper binary.
    cd lexical
    make clean >/dev/null 2>&1 || true
    make
    cd ..

    # Prepare a tiny Java sample input for extractor.
    SMOKE_SRC="${WORK_DIR}/src"
    mkdir -p "$SMOKE_SRC"
    cat > "${SMOKE_SRC}/Sample.java" <<'EOF'
public class Sample {
    int f(int x) {
        int y = x + 1;
        if (y > 10) {
            y = y - 2;
        }
        return y;
    }
}
EOF

    # Clean prior generated files in artifact workspace.
    rm -rf input/* output/*
    find token -type f -delete || true
    rm -f function.file tokenline_num clones
    chmod +x txl/*.x || true

    # Execute native pipeline as documented by artifact runner.
    ./extract ./txl java functions "$SMOKE_SRC" ./input 2
    ./parser ./input ./ 2
    ./tokenize ./function.file ./token ./ 2
    ./detect ./token ./output ./function.file 6 1 0.6
    ./co1 ./output ./

    echo "Smoke test completed."
    echo "Generated outputs:"
    ls -la ./output || true
} > "$LOG_FILE" 2>&1

echo "Smoke test log written to $LOG_FILE"
