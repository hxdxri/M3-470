#!/usr/bin/env bash
# run_full_pipeline.sh — Foundation pipeline for CCAligner milestone workflow
# revision: 2026-03-12-benchmark-stage
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
echo "Step 3: prepare BigCloneBench subset"
BCB_N="${BCB_N:-200}"
BCB_SEED="${BCB_SEED:-42}"
python3 "${ROOT_DIR}/scripts/10_prepare_bigclonebench_subset.py" \
  --n "${BCB_N}" --seed "${BCB_SEED}" \
  --output-dir "${ROOT_DIR}/data/bigclonebench_subset" \
  --evidence-dir "${ROOT_DIR}/evidence/logs"

echo ""
echo "Step 4: run CCAligner benchmark"
bash "${ROOT_DIR}/scripts/30_run_ccaligner_benchmark.sh" \
  "${ROOT_DIR}/data/bigclonebench_subset/src" \
  "${ROOT_DIR}/out/ccaligner"

echo ""
echo "Step 5: evaluate against oracle"
python3 "${ROOT_DIR}/scripts/60_eval_bigclonebench.py" \
  --oracle "${ROOT_DIR}/data/bigclonebench_subset/oracle/oracle_pairs.jsonl" \
  --clones "${ROOT_DIR}/out/ccaligner/clones.csv" \
  --results-dir "${ROOT_DIR}/results" \
  --eval-dir "${ROOT_DIR}/out/eval"

date -u > "${LOG_DIR}/pipeline_last_run_utc.txt"
echo "Foundation pipeline complete."
