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
import json

out_dir = "${BCB_DIR}"
os.makedirs(out_dir, exist_ok=True)

ds = load_dataset(
    "google/code_x_glue_cc_clone_detection_big_clone_bench",
    split="train",
    streaming=True
)

N = int("${N_PAIRS}")
i = 0
manifest = []
oracle_pairs = []
index_to_snippet_id = {}
for ex in ds:
    # Save func1
    fname1 = f"{i}_func1.java"
    with open(os.path.join(out_dir, fname1), "w", encoding="utf-8") as f:
        f.write(ex["func1"])
    manifest.append({
        "snippet_id": ex["id1"],
        "file_path": f"src/{str(ex['id1'])[:4]}/Snippet_{ex['id1']}.java"
    })
    index_to_snippet_id[i * 2] = ex["id1"]
    # Save func2
    fname2 = f"{i}_func2.java"
    with open(os.path.join(out_dir, fname2), "w", encoding="utf-8") as f:
        f.write(ex["func2"])
    manifest.append({
        "snippet_id": ex["id2"],
        "file_path": f"src/{str(ex['id2'])[:4]}/Snippet_{ex['id2']}.java"
    })
    index_to_snippet_id[i * 2 + 1] = ex["id2"]
    # Add to oracle
    oracle_pairs.append({
        "pair_id": i,
        "id1": ex["id1"],
        "id2": ex["id2"],
        "file1": f"src/{str(ex['id1'])[:4]}/Snippet_{ex['id1']}.java",
        "file2": f"src/{str(ex['id2'])[:4]}/Snippet_{ex['id2']}.java",
        "label": ex["label"]
    })
    i += 1
    if i >= N:
        break

# Write manifest
manifest_path = os.path.join(out_dir, "bcb_subset_manifest.json")
with open(manifest_path, "w", encoding="utf-8") as mf:
    json.dump(manifest, mf, indent=2)

# Write oracle
oracle_path = os.path.join(out_dir, "oracle_pairs.jsonl")
with open(oracle_path, "w", encoding="utf-8") as of:
    for pair in oracle_pairs:
        of.write(json.dumps(pair) + "\n")

# Write index-to-snippet-id mapping
index_map_path = os.path.join(out_dir, "index_to_snippet_id.json")
with open(index_map_path, "w", encoding="utf-8") as imf:
    json.dump(index_to_snippet_id, imf, indent=2)

print(f"Wrote {2*N} .java files to {out_dir}")
print(f"Wrote manifest to {manifest_path}")
print(f"Wrote oracle to {oracle_path}")
print(f"Wrote index map to {index_map_path}")
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
echo "Wrote index map to {index_map_path}"

cd "${CLONE_DIR}"
rm -f scriptinator_metadata.scc Log_*.out Lpython3 scripts/evaluate_bcb.py \
  --oracle /workspace/benchmarks/bcb_subset/oracle_pairs.jsonl \
  --results /workspace/SourcererCC/results/bcb_subset_results.pairs \
  --index_map /workspace/benchmarks/bcb_subset/index_to_snippet_id.json \
  --metrics /workspace/SourcererCC/results/sourcerercc_metrics.jsonog_*.err
rm -rf NODE_*
python3 controller.py 2>&1 | tee "${LOG_DIR}/bcb_clone_detector.log"

echo "[6/6] Aggregating results"
cat NODE_*/output8.0/query_* > results.pairs
wc -l results.pairs | tee "${RES_DIR}/bcb_subset_results.count"
cp results.pairs "${RES_DIR}/bcb_subset_results.pairs"

echo "DONE Results: ${RES_DIR}/bcb_subset_results.pairs"