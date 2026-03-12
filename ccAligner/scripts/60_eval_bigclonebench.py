#!/usr/bin/env python3
"""
Evaluate CCAligner clone output against BigCloneBench subset oracle.
"""

import argparse
import json
import re
from pathlib import Path


def snippet_id_from_path(path: str):
    m = re.search(r"Snippet_(\d+)\.java", path)
    return int(m.group(1)) if m else None


def load_oracle(path: Path):
    rows = []
    with path.open("r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if line:
                rows.append(json.loads(line))
    return rows


def load_detected_pairs(clones_csv: Path):
    pairs = set()
    if not clones_csv.exists():
        return pairs

    with clones_csv.open("r", encoding="utf-8") as f:
        for raw in f:
            line = raw.strip()
            if not line:
                continue
            parts = [p.strip() for p in line.split(",")]
            if len(parts) < 6:
                continue
            p1, p2 = parts[0], parts[3]
            id1 = snippet_id_from_path(p1)
            id2 = snippet_id_from_path(p2)
            if id1 is None or id2 is None:
                continue
            pairs.add((min(id1, id2), max(id1, id2)))
    return pairs


def main():
    parser = argparse.ArgumentParser(description="Evaluate CCAligner on BCB subset")
    parser.add_argument("--oracle", required=True)
    parser.add_argument("--clones", required=True)
    parser.add_argument(
        "--oracle-mode",
        default="auto",
        choices=["auto", "sampled", "induced"],
        help="auto: prefer induced oracle file if present",
    )
    parser.add_argument("--results-dir", default="results")
    parser.add_argument("--eval-dir", default="out/eval")
    args = parser.parse_args()

    oracle_path = Path(args.oracle)
    if args.oracle_mode in ("auto", "induced"):
        induced_path = oracle_path.with_name("oracle_pairs_induced.jsonl")
        if induced_path.exists():
            oracle_path = induced_path
        elif args.oracle_mode == "induced":
            raise FileNotFoundError(f"induced oracle not found: {induced_path}")

    oracle_rows = load_oracle(oracle_path)
    detected = load_detected_pairs(Path(args.clones))

    oracle_pos = set()
    oracle_neg = set()
    oracle_all = set()
    for row in oracle_rows:
        pair = (min(int(row["id1"]), int(row["id2"])), max(int(row["id1"]), int(row["id2"])))
        oracle_all.add(pair)
        if row["label"]:
            oracle_pos.add(pair)
        else:
            oracle_neg.add(pair)

    tp_pairs = detected & oracle_pos
    fp_pairs = detected & oracle_neg
    fn_pairs = oracle_pos - detected
    tn_pairs = oracle_neg - detected
    unknown_pairs = detected - oracle_all

    tp = len(tp_pairs)
    fp = len(fp_pairs)
    fn = len(fn_pairs)
    tn = len(tn_pairs)
    unknown = len(unknown_pairs)

    # Precision/recall over labeled oracle space only.
    labeled_detected = detected & oracle_all
    labeled_tp = len(labeled_detected & oracle_pos)
    labeled_fp = len(labeled_detected & oracle_neg)
    labeled_precision = labeled_tp / (labeled_tp + labeled_fp) if (labeled_tp + labeled_fp) else 0.0
    recall = tp / (tp + fn) if (tp + fn) else 0.0
    f1 = 2 * labeled_precision * recall / (labeled_precision + recall) if (labeled_precision + recall) else 0.0
    labeled_coverage = len(labeled_detected) / len(detected) if detected else 0.0

    metrics = {
        "tool": "CCAligner",
        "benchmark": "BigCloneBench (CodeXGLUE subset)",
        "oracle_file": str(oracle_path),
        "oracle_positive_pairs": len(oracle_pos),
        "oracle_negative_pairs": len(oracle_neg),
        "detected_pairs": len(detected),
        "true_positives": tp,
        "false_positives": fp,
        "true_negatives": tn,
        "false_negatives": fn,
        "unknown_detected": unknown,
        "precision_labeled_pairs_only": round(labeled_precision, 4),
        "recall_sampled_positive_pairs": round(recall, 4),
        "f1_labeled_pairs_only": round(f1, 4),
        "labeled_detection_coverage": round(labeled_coverage, 4),
    }

    results_dir = Path(args.results_dir)
    eval_dir = Path(args.eval_dir)
    results_dir.mkdir(parents=True, exist_ok=True)
    eval_dir.mkdir(parents=True, exist_ok=True)

    (results_dir / "ccaligner_metrics.json").write_text(json.dumps(metrics, indent=2), encoding="utf-8")
    (eval_dir / "metrics.json").write_text(json.dumps(metrics, indent=2), encoding="utf-8")

    fp_sample = [{"id1": a, "id2": b} for a, b in list(fp_pairs)[:20]]
    fn_sample = [{"id1": a, "id2": b} for a, b in list(fn_pairs)[:20]]
    (eval_dir / "false_positives_sample.json").write_text(json.dumps(fp_sample, indent=2), encoding="utf-8")
    (eval_dir / "false_negatives_sample.json").write_text(json.dumps(fn_sample, indent=2), encoding="utf-8")

    print(json.dumps(metrics, indent=2))


if __name__ == "__main__":
    main()
