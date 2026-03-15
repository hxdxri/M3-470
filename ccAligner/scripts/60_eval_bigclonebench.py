#!/usr/bin/env python3
"""Evaluate CCAligner output against the sampled BigCloneBench oracle."""

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


def load_full_dataset_oracle(selected_snippet_ids, split="train"):
    try:
        from datasets import load_dataset
    except ImportError as e:
        raise RuntimeError(
            "datasets library is required for full dataset evaluation. Install with: python3 -m pip install datasets pyarrow"
        ) from e

    import sys
    print(f"Loading full BigCloneBench dataset split '{split}' to build oracle map...", flush=True)
    ds = load_dataset("google/code_x_glue_cc_clone_detection_big_clone_bench", split=split, streaming=True)
    pair_labels = {}
    count = 0
    matched = 0
    for ex in ds:
        id1 = int(ex["id1"])
        id2 = int(ex["id2"])
        if id1 in selected_snippet_ids and id2 in selected_snippet_ids:
            pair = (min(id1, id2), max(id1, id2))
            pair_labels[pair] = bool(ex["label"])
            matched += 1
        count += 1
        if count % 100_000 == 0:
            print(f"  scanned {count:,} rows, matched {matched:,} pairs", flush=True)
    print(f"Full dataset scan complete: scanned {count:,} rows, matched {matched:,} labeled pairs", flush=True)
    return pair_labels


def main():
    parser = argparse.ArgumentParser(description="Evaluate CCAligner on BCB subset")
    parser.add_argument("--oracle", required=True)
    parser.add_argument("--clones", required=True)
    parser.add_argument("--results-dir", default="results")
    parser.add_argument("--eval-dir", default="out/eval")
    parser.add_argument(
        "--metrics-name",
        default="ccaligner_metrics.json",
        help="output filename for metrics JSON (written to results-dir and eval-dir)",
    )
    parser.add_argument(
        "--full-dataset-split",
        default=None,
        help="Optional full dataset split (e.g. train) to label detected pairs among selected snippets (streaming).",
    )
    args = parser.parse_args()

    oracle_path = Path(args.oracle)
    oracle_rows = load_oracle(oracle_path)
    detected = load_detected_pairs(Path(args.clones))

    oracle_pos = set()
    oracle_neg = set()
    oracle_all = set()
    selected_snippets = set()
    for row in oracle_rows:
        id1 = int(row["id1"])
        id2 = int(row["id2"])
        pair = (min(id1, id2), max(id1, id2))
        oracle_all.add(pair)
        selected_snippets.add(id1)
        selected_snippets.add(id2)
        if row["label"]:
            oracle_pos.add(pair)
        else:
            oracle_neg.add(pair)

    # Optionally expand evaluation using full BigCloneBench labeled pairs among selected snippets.
    full_labels = None
    if args.full_dataset_split:
        full_labels = load_full_dataset_oracle(selected_snippets, split=args.full_dataset_split)
        # fill in unlabeled with None for detected pairs among selected snippets if missing
        for p in detected:
            if p[0] in selected_snippets and p[1] in selected_snippets:
                if p not in full_labels:
                    full_labels[p] = None
        print(f"Using full dataset oracle for selected snippets: {len([x for x in full_labels if full_labels[x] is not None])} pairs labeled")

    if full_labels is not None:
        label_map = full_labels
        oracle_all = set(label_map.keys())
        oracle_pos = {p for p,v in label_map.items() if v is True}
        oracle_neg = {p for p,v in label_map.items() if v is False}
        print("Evaluation mode: full dataset labels among selected snippets")
    else:
        label_map = {p: True for p in oracle_pos}
        label_map.update({p: False for p in oracle_neg})
        print("Evaluation mode: sampled oracle labels only")

    tp_pairs = detected & oracle_pos
    fp_pairs = detected & oracle_neg
    fn_pairs = oracle_pos - detected
    unscored_pairs = detected - oracle_all

    tp = len(tp_pairs)
    fp = len(fp_pairs)
    fn = len(fn_pairs)
    unscored = len(unscored_pairs)

    scored_detected = detected & oracle_all
    precision = tp / (tp + fp) if (tp + fp) else 0.0
    recall = tp / (tp + fn) if (tp + fn) else 0.0
    f1 = 2 * precision * recall / (precision + recall) if (precision + recall) else 0.0
    scored_detection_coverage = len(scored_detected) / len(detected) if detected else 0.0
    selected_snippet_coverage = len(selected_snippets)
    detected_selected_snippet_pairs = {
        p
        for p in detected
        if p[0] in selected_snippets and p[1] in selected_snippets
    }
    detected_selected_snippet_pair_count = len(detected_selected_snippet_pairs)

    metrics = {
        "tool": "CCAligner",
        "benchmark": "BigCloneBench (CodeXGLUE subset)",
        "oracle_file": str(oracle_path),
        "total_sampled_pairs": len(oracle_all),
        "oracle_positive_pairs": len(oracle_pos),
        "oracle_negative_pairs": len(oracle_neg),
        "selected_snippets": selected_snippet_coverage,
        "detected_pairs": len(detected),
        "detected_pairs_within_selected_snippets": detected_selected_snippet_pair_count,
        "scored_detected_pairs": len(scored_detected),
        "unscored_detected_pairs": unscored,
        "true_positives": tp,
        "false_positives": fp,
        "false_negatives": fn,
        "precision": round(precision, 4),
        "recall": round(recall, 4),
        "f1": round(f1, 4),
        "scored_detection_coverage": round(scored_detection_coverage, 4),
    }

    results_dir = Path(args.results_dir)
    eval_dir = Path(args.eval_dir)
    results_dir.mkdir(parents=True, exist_ok=True)
    eval_dir.mkdir(parents=True, exist_ok=True)

    (results_dir / args.metrics_name).write_text(json.dumps(metrics, indent=2), encoding="utf-8")
    (eval_dir / args.metrics_name).write_text(json.dumps(metrics, indent=2), encoding="utf-8")

    fp_sample = [{"id1": a, "id2": b} for a, b in list(fp_pairs)[:20]]
    fn_sample = [{"id1": a, "id2": b} for a, b in list(fn_pairs)[:20]]
    unscored_sample = [{"id1": a, "id2": b} for a, b in list(unscored_pairs)[:20]]
    (eval_dir / "false_positives_sample.json").write_text(json.dumps(fp_sample, indent=2), encoding="utf-8")
    (eval_dir / "false_negatives_sample.json").write_text(json.dumps(fn_sample, indent=2), encoding="utf-8")
    (eval_dir / "unscored_detected_pairs_sample.json").write_text(
        json.dumps(unscored_sample, indent=2),
        encoding="utf-8",
    )

    print("=== CCAligner BCB subset evaluation summary ===")
    print("Total sampled pairs:", len(oracle_all))
    print("Oracle positive:", len(oracle_pos), "negative:", len(oracle_neg))
    print("Detected pairs:", len(detected))
    print("Detected pairs within selected snippets:", detected_selected_snippet_pair_count)
    print("Scored detected pairs (in sampled oracle):", len(scored_detected))
    print("Unscored detected pairs:", unscored)
    print("True positives:", tp, "False positives:", fp, "False negatives:", fn)
    print("Precision:", round(precision,4), "Recall:", round(recall,4), "F1:", round(f1,4))
    print("(Unscored detections are expected when CCAligner finds pairs that were not in the sampled labeled set.)")
    print(json.dumps(metrics, indent=2))


if __name__ == "__main__":
    main()
