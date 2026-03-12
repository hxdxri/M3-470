#!/usr/bin/env python3
"""
10_prepare_bigclonebench_subset.py

Downloads BigCloneBench from HuggingFace (CodeXGLUE version) and materializes
a subset of Java code snippets into individual files, plus an oracle pairs file
for evaluation.

Usage:
    python3 scripts/10_prepare_bigclonebench_subset.py \
        --n 2000 --seed 42 \
        --output-dir data/bigclonebench_subset \
        --evidence-dir evidence/logs
"""

import argparse
import json
import os
import sys
import hashlib
from pathlib import Path

def main():
    parser = argparse.ArgumentParser(
        description="Prepare BigCloneBench subset for CloneWorks evaluation"
    )
    parser.add_argument(
        "--n", type=int, default=2000,
        help="Number of pairs to include in subset (default: 2000)"
    )
    parser.add_argument(
        "--seed", type=int, default=42,
        help="Random seed for reproducibility (default: 42)"
    )
    parser.add_argument(
        "--split", type=str, default="train",
        help="Dataset split to use: train, validation, test (default: train)"
    )
    parser.add_argument(
        "--output-dir", type=str, default="data/bigclonebench_subset",
        help="Output directory for subset files"
    )
    parser.add_argument(
        "--evidence-dir", type=str, default="evidence/logs",
        help="Directory for evidence/manifest files"
    )
    args = parser.parse_args()

    print(f"=== BigCloneBench Subset Preparation ===")
    print(f"N pairs     : {args.n}")
    print(f"Seed        : {args.seed}")
    print(f"Split       : {args.split}")
    print(f"Output dir  : {args.output_dir}")
    print()

    # Load dataset from HuggingFace
    try:
        from datasets import load_dataset
    except ImportError:
        print("ERROR: 'datasets' package not installed. Run: pip3 install datasets")
        sys.exit(1)

    print("Loading BigCloneBench from HuggingFace...")
    ds = load_dataset(
        "google/code_x_glue_cc_clone_detection_big_clone_bench",
        split=args.split,
        trust_remote_code=True
    )
    print(f"Dataset loaded: {len(ds)} pairs in '{args.split}' split")

    # Sample subset 
    import random
    random.seed(args.seed)

    total = len(ds)
    if args.n > total:
        print(f"WARNING: Requested {args.n} pairs but only {total} available. Using all.")
        args.n = total

    indices = sorted(random.sample(range(total), args.n))
    subset = ds.select(indices)
    print(f"Selected {len(subset)} pairs")

    #Count positive / negative
    pos_count = sum(1 for ex in subset if ex["label"])
    neg_count = len(subset) - pos_count
    print(f"Positive (clone) pairs: {pos_count}")
    print(f"Negative (non-clone) pairs: {neg_count}")

    #  Materialize source files 
    src_dir = Path(args.output_dir) / "src"
    oracle_dir = Path(args.output_dir) / "oracle"
    src_dir.mkdir(parents=True, exist_ok=True)
    oracle_dir.mkdir(parents=True, exist_ok=True)

    manifest = []  # list of {snippet_id, file_path, func_hash}
    written_snippets = {}  # snippet_id -> file_path (dedup)
    oracle_pairs = []  # list of {id, id1, id2, file1, file2, label}

    def write_snippet(snippet_id, func_code):
        """Write a single Java snippet to disk, deduplicating by snippet_id."""
        if snippet_id in written_snippets:
            return written_snippets[snippet_id]

        # Organize into subdirectories to avoid huge flat dirs
        subdir = f"{snippet_id // 10000:04d}"
        file_dir = src_dir / subdir
        file_dir.mkdir(parents=True, exist_ok=True)

        # Create a valid Java class wrapper
        class_name = f"Snippet_{snippet_id}"
        java_content = (
            f"// BigCloneBench snippet ID: {snippet_id}\n"
            f"public class {class_name} {{\n"
            f"{func_code}\n"
            f"}}\n"
        )

        file_path = file_dir / f"{class_name}.java"
        file_path.write_text(java_content, encoding="utf-8")

        rel_path = str(file_path.relative_to(Path(args.output_dir)))
        written_snippets[snippet_id] = rel_path

        func_hash = hashlib.sha256(func_code.encode("utf-8")).hexdigest()[:16]
        manifest.append({
            "snippet_id": snippet_id,
            "file_path": rel_path,
            "func_hash": func_hash
        })

        return rel_path

    print("\nMaterializing source files...")
    for ex in subset:
        pair_id = ex["id"]
        id1 = ex["id1"]
        id2 = ex["id2"]
        func1 = ex["func1"]
        func2 = ex["func2"]
        label = bool(ex["label"])

        file1 = write_snippet(id1, func1)
        file2 = write_snippet(id2, func2)

        oracle_pairs.append({
            "pair_id": pair_id,
            "id1": id1,
            "id2": id2,
            "file1": file1,
            "file2": file2,
            "label": label
        })

    print(f"Written {len(written_snippets)} unique Java files")
    print(f"Oracle contains {len(oracle_pairs)} pairs")

    # Write oracle file 
    oracle_file = oracle_dir / "oracle_pairs.jsonl"
    with open(oracle_file, "w", encoding="utf-8") as f:
        for pair in oracle_pairs:
            f.write(json.dumps(pair) + "\n")
    print(f"Oracle written to: {oracle_file}")

    # Also write a CSV version for easy inspection
    oracle_csv = oracle_dir / "oracle_pairs.csv"
    with open(oracle_csv, "w", encoding="utf-8") as f:
        f.write("pair_id,id1,id2,file1,file2,label\n")
        for pair in oracle_pairs:
            f.write(f"{pair['pair_id']},{pair['id1']},{pair['id2']},"
                    f"{pair['file1']},{pair['file2']},{pair['label']}\n")
    print(f"Oracle CSV written to: {oracle_csv}")

    # Write evidence files 
    evidence_dir = Path(args.evidence_dir)
    evidence_dir.mkdir(parents=True, exist_ok=True)

    # Manifest
    manifest_file = evidence_dir / "bcb_subset_manifest.json"
    with open(manifest_file, "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2)
    print(f"Manifest written to: {manifest_file}")

    # Parameters
    params_file = evidence_dir / "bcb_subset_params.txt"
    with open(params_file, "w", encoding="utf-8") as f:
        f.write(f"dataset=google/code_x_glue_cc_clone_detection_big_clone_bench\n")
        f.write(f"split={args.split}\n")
        f.write(f"total_pairs_in_split={total}\n")
        f.write(f"subset_n={args.n}\n")
        f.write(f"seed={args.seed}\n")
        f.write(f"positive_pairs={pos_count}\n")
        f.write(f"negative_pairs={neg_count}\n")
        f.write(f"unique_snippets={len(written_snippets)}\n")
        f.write(f"selection_method=random.sample(range(total), n) with seed={args.seed}\n")
        f.write(f"output_dir={args.output_dir}\n")
    print(f"Parameters written to: {params_file}")

    print("\n=== Done ===")


if __name__ == "__main__":
    main()
