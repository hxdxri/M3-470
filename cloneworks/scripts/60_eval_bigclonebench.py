#!/usr/bin/env python3
"""
60_eval_bigclonebench.py

Evaluate CloneWorks results against the BigCloneBench oracle subset.

Reads:
  - Oracle pairs:  data/bigclonebench_subset/oracle/oracle_pairs.jsonl
  - CW clones:     out/cwformat/clones_formatted.jsonl
  - CW file map:   out/cwbuild/bigclonebench.files

Outputs:
  - results/cloneworks_metrics.json
  - out/eval/metrics.json
  - out/eval/false_positives_sample.json
  - out/eval/false_negatives_sample.json

Usage:
    python3 scripts/60_eval_bigclonebench.py \
        --oracle data/bigclonebench_subset/oracle/oracle_pairs.jsonl \
        --clones out/cwformat/clones_formatted.jsonl \
        --filemap out/cwbuild/bigclonebench.files \
        --src-root data/bigclonebench_subset/src \
        --results-dir results \
        --eval-dir out/eval
"""

import argparse
import json
import os
import re
import sys
from collections import defaultdict
from pathlib import Path


def extract_snippet_id_from_path(path):
    """Extract snippet ID from a file path like .../Snippet_12345.java"""
    match = re.search(r'Snippet_(\d+)\.java', path)
    if match:
        return int(match.group(1))
    return None


def load_oracle(oracle_path):
    """Load oracle pairs from JSONL file."""
    pairs = []
    with open(oracle_path, "r") as f:
        for line in f:
            line = line.strip()
            if line:
                pairs.append(json.loads(line))
    return pairs


def load_fileid_map(filemap_path):
    """Load CloneWorks fileID -> filePath mapping."""
    mapping = {}
    with open(filemap_path, "r") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            parts = line.split("\t")
            if len(parts) < 2:
                parts = line.split(None, 1)
            if len(parts) >= 2:
                try:
                    fid = int(parts[0])
                    fpath = parts[1]
                    mapping[fid] = fpath
                except ValueError:
                    continue
    return mapping


def load_clones(clones_path):
    """Load formatted clone pairs from JSONL."""
    pairs = []
    with open(clones_path, "r") as f:
        for line in f:
            line = line.strip()
            if line:
                pairs.append(json.loads(line))
    return pairs


def main():
    parser = argparse.ArgumentParser(
        description="Evaluate CloneWorks against BigCloneBench oracle"
    )
    parser.add_argument("--oracle", required=True, help="Path to oracle_pairs.jsonl")
    parser.add_argument("--clones", required=True, help="Path to clones_formatted.jsonl")
    parser.add_argument("--filemap", required=True, help="Path to bigclonebench.files")
    parser.add_argument("--src-root", default="data/bigclonebench_subset/src",
                        help="Source root used during cwbuild")
    parser.add_argument("--results-dir", default="results",
                        help="Directory to write metrics")
    parser.add_argument("--eval-dir", default="out/eval",
                        help="Directory to write evaluation details")
    args = parser.parse_args()

    print("=== CloneWorks Evaluation ===")
    print(f"Oracle  : {args.oracle}")
    print(f"Clones  : {args.clones}")
    print(f"Filemap : {args.filemap}")
    print()

    # ---- Load data ----
    oracle_pairs = load_oracle(args.oracle)
    fileid_map = load_fileid_map(args.filemap)
    clone_pairs = load_clones(args.clones)

    print(f"Oracle pairs : {len(oracle_pairs)}")
    print(f"File IDs     : {len(fileid_map)}")
    print(f"Clone pairs  : {len(clone_pairs)}")
    print()

    # ---- Build snippet_id -> fileID mapping ----
    # Reverse: from fileid_map, extract snippet IDs from paths
    fileid_to_snippet = {}
    for fid, fpath in fileid_map.items():
        sid = extract_snippet_id_from_path(fpath)
        if sid is not None:
            fileid_to_snippet[fid] = sid

    # ---- Build set of detected clone pairs (by snippet IDs) ----
    detected_pairs = set()
    for cp in clone_pairs:
        fid1 = cp["file1_id"]
        fid2 = cp["file2_id"]
        sid1 = fileid_to_snippet.get(fid1)
        sid2 = fileid_to_snippet.get(fid2)
        if sid1 is not None and sid2 is not None:
            pair = (min(sid1, sid2), max(sid1, sid2))
            detected_pairs.add(pair)

    print(f"Unique detected pairs (by snippet ID): {len(detected_pairs)}")

    # ---- Build oracle sets ----
    oracle_positive = set()  # True clone pairs
    oracle_negative = set()  # Non-clone pairs
    oracle_all = set()

    for op in oracle_pairs:
        id1 = op["id1"]
        id2 = op["id2"]
        pair = (min(id1, id2), max(id1, id2))
        oracle_all.add(pair)
        if op["label"]:
            oracle_positive.add(pair)
        else:
            oracle_negative.add(pair)

    print(f"Oracle positive pairs: {len(oracle_positive)}")
    print(f"Oracle negative pairs: {len(oracle_negative)}")
    print()

    # ---- Compute metrics ----
    # True Positives: detected AND in oracle_positive
    tp_pairs = detected_pairs & oracle_positive
    tp = len(tp_pairs)

    # False Positives: detected AND in oracle_negative
    fp_pairs = detected_pairs & oracle_negative
    fp = len(fp_pairs)

    # False Negatives: oracle_positive but NOT detected
    fn_pairs = oracle_positive - detected_pairs
    fn = len(fn_pairs)

    # True Negatives: oracle_negative and NOT detected
    tn_pairs = oracle_negative - detected_pairs
    tn = len(tn_pairs)

    # Also count detected pairs not in oracle at all (unknown)
    unknown_detected = detected_pairs - oracle_all
    unknown_count = len(unknown_detected)

    precision = tp / (tp + fp) if (tp + fp) > 0 else 0.0
    recall = tp / (tp + fn) if (tp + fn) > 0 else 0.0
    f1 = 2 * precision * recall / (precision + recall) if (precision + recall) > 0 else 0.0

    print("=== Results ===")
    print(f"True Positives  : {tp}")
    print(f"False Positives : {fp}")
    print(f"True Negatives  : {tn}")
    print(f"False Negatives : {fn}")
    print(f"Unknown (not in oracle): {unknown_count}")
    print(f"Precision       : {precision:.4f}")
    print(f"Recall          : {recall:.4f}")
    print(f"F1 Score        : {f1:.4f}")
    print()

    # ---- Save metrics ----
    metrics = {
        "tool": "CloneWorks",
        "benchmark": "BigCloneBench (CodeXGLUE subset)",
        "oracle_positive_pairs": len(oracle_positive),
        "oracle_negative_pairs": len(oracle_negative),
        "detected_pairs": len(detected_pairs),
        "true_positives": tp,
        "false_positives": fp,
        "true_negatives": tn,
        "false_negatives": fn,
        "unknown_detected": unknown_count,
        "precision": round(precision, 4),
        "recall": round(recall, 4),
        "f1_score": round(f1, 4),
    }

    results_dir = Path(args.results_dir)
    results_dir.mkdir(parents=True, exist_ok=True)
    eval_dir = Path(args.eval_dir)
    eval_dir.mkdir(parents=True, exist_ok=True)

    # Write to both locations
    for out_path in [results_dir / "cloneworks_metrics.json", eval_dir / "metrics.json"]:
        with open(out_path, "w") as f:
            json.dump(metrics, f, indent=2)
        print(f"Metrics written to: {out_path}")

    # ---- Sample false positives and false negatives ----
    sample_size = min(20, max(len(fp_pairs), len(fn_pairs)))

    fp_sample = list(fp_pairs)[:sample_size]
    fn_sample = list(fn_pairs)[:sample_size]

    with open(eval_dir / "false_positives_sample.json", "w") as f:
        json.dump([{"id1": p[0], "id2": p[1]} for p in fp_sample], f, indent=2)
    print(f"FP sample written to: {eval_dir / 'false_positives_sample.json'}")

    with open(eval_dir / "false_negatives_sample.json", "w") as f:
        json.dump([{"id1": p[0], "id2": p[1]} for p in fn_sample], f, indent=2)
    print(f"FN sample written to: {eval_dir / 'false_negatives_sample.json'}")

    print("\n=== Evaluation Complete ===")


if __name__ == "__main__":
    main()
