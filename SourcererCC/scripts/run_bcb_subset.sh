#!/usr/bin/env bash
set -euo pipefail

# ---- Config ----
N_PAIRS="${1:-100}"   # number of BigCloneBench pairs to stream (default 100)
WORKDIR="/workspace"
BCB_DIR="${WORKDIR}/benchmarks/bcb_subset"
BCB_ZIP="${WORKDIR}/benchmarks/bcb_subset.zip"
TOK_DIR="${WORKDIR}/tokenizers/file-level"
CLONE_DIR="${WORKDIR}/clone-detector"
LOG_DIR="${WORKDIR}/SourcererCC/logs"
RES_DIR="${WORKDIR}/SourcererCC/results"

mkdir -p "${LOG_DIR}" "${RES_DIR}" "${WORKDIR}/benchmarks"

echo "[1/6] Installing Python dependency (datasets)"
pip3 install -q datasets

echo "[2/6] Creating BigCloneBench subset (streaming) - ${N_PAIRS} pairs"
rm -rf "${BCB_DIR}"
mkdir -p "${BCB_DIR}"

export HF_HUB_DISABLE_TELEMETRY=1
export HF_HOME=/workspace/.hf_cache
export HF_DATASETS_CACHE=/workspace/.hf_cache
mkdir -p /workspace/.hf_cache

python3 - << PY
from datasets import load_dataset
import os

out_dir = "${BCB_DIR}"
os.makedirs(out_dir, exist_ok=True)

ds = load_dataset(
    "google/code_x_glue_cc_clone_detection_big_clone_bench",
    split="train",
    streaming=True
)

N = int("${N_PAIRS}")
i = 0
for ex in ds:
    with open(os.path.join(out_dir, f"{i}_func1.java"), "w", encoding="utf-8") as f:
        f.write(ex["func1"])
    with open(os.path.join(out_dir, f"{i}_func2.java"), "w", encoding="utf-8") as f:
        f.write(ex["func2"])
    i += 1
    if i >= N:
        break

print(f"Wrote {2*N} .java files to {out_dir}")
PY

echo "[3/6] Zipping subset into a single 'project'"
cd "${WORKDIR}/benchmarks"
rm -f "${BCB_ZIP}"
zip -qr "${BCB_ZIP}" "bcb_subset"

echo "[4/6] Tokenizing (SourcererCC tokenizer)"
cd "${TOK_DIR}"
echo "${BCB_ZIP}" > project-list.txt
sed -i 's/^File_extensions *=.*/File_extensions = .java/' config.ini
rm -rf bookkeeping_projs files_stats files_tokens logs
python3 tokenizer.py zip 2>&1 | tee "${LOG_DIR}/bcb_tokenizer.log"

echo "[5/6] Running clone detector (controller.py)"
cat files_tokens/* > blocks.file
cp blocks.file "${CLONE_DIR}/input/dataset/"

cd "${CLONE_DIR}"
rm -f scriptinator_metadata.scc Log_*.out Log_*.err
rm -rf NODE_*
python3 controller.py 2>&1 | tee "${LOG_DIR}/bcb_clone_detector.log"

echo "[6/6] Aggregating results"
cat NODE_*/output8.0/query_* > results.pairs
wc -l results.pairs | tee "${RES_DIR}/bcb_subset_results.count"
cp results.pairs "${RES_DIR}/bcb_subset_results.pairs"

echo "DONE Results: ${RES_DIR}/bcb_subset_results.pairs"