#!/usr/bin/env bash
# run_full_pipeline.sh — Foundation pipeline for CCAligner milestone workflow
# revision: 2026-03-12-smoke-path-fix
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LOG_DIR="${ROOT_DIR}/evidence/logs"
mkdir -p "$LOG_DIR"

echo "=== CCAligner Foundation Pipeline ==="
echo "Step 1: fetch artifact"
bash "${ROOT_DIR}/scripts/01_fetch_artifact.sh"

echo ""
echo "Step 2: run smoke test"
bash "${ROOT_DIR}/scripts/20_smoke_test.sh"

echo ""
echo "Step 3+: benchmark stages are pending implementation in next increment."
echo "Targets: BigCloneBench/BigCloneEval + mutation-framework emulation."
echo "See BenchmarksUsed-README.md for benchmark specs."

date -u > "${LOG_DIR}/pipeline_last_run_utc.txt"
echo "Foundation pipeline complete."
