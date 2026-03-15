#!/usr/bin/env python3
"""Prepare a sampled BigCloneBench subset for CCAligner."""

import argparse
import json
import os
import random
import subprocess
import sys
from pathlib import Path


def ensure_datasets():
    repo_root = Path(__file__).resolve().parents[1]
    dep_dir = Path(os.environ.get("CCALIGNER_PY_DEPS", str(repo_root / ".pydeps")))
    dep_dir.mkdir(parents=True, exist_ok=True)
    dep_path = str(dep_dir)
    if dep_path not in sys.path:
        sys.path.insert(0, dep_path)
    try:
        from datasets import load_dataset  # noqa: F401
        return
    except ImportError:
        print(f"datasets not found; installing dependencies into {dep_path} ...")
        cmd = [
            sys.executable,
            "-m",
            "pip",
            "install",
            "--target",
            dep_path,
            "datasets==2.13.2",
            "pyarrow==12.0.1",
            "multiprocess==0.70.14",
            "dill==0.3.6",
            "urllib3<2",
            "requests==2.28.2",
        ]
        subprocess.check_call(cmd)
        if dep_path not in sys.path:
            sys.path.insert(0, dep_path)
        from datasets import load_dataset  # noqa: F401


def wrap_java(snippet_id: int, func_code: str) -> str:
    class_name = f"Snippet_{snippet_id}"
    return (
        f"// BigCloneBench snippet ID: {snippet_id}\n"
        f"public class {class_name} {{\n"
        f"{func_code}\n"
        "}\n"
    )


def main():
    parser = argparse.ArgumentParser(description="Prepare BigCloneBench subset for CCAligner")
    parser.add_argument("--n", type=int, default=200, help="number of pairs to sample")
    parser.add_argument("--seed", type=int, default=42)
    parser.add_argument("--split", default="train")
    parser.add_argument("--output-dir", default="data/bigclonebench_subset")
    parser.add_argument("--evidence-dir", default="evidence/logs")
    args = parser.parse_args()

    ensure_datasets()
    from datasets import load_dataset

    print("Loading dataset...")
    ds = load_dataset(
        "google/code_x_glue_cc_clone_detection_big_clone_bench",
        split=args.split,
    )

    total = len(ds)
    n = min(args.n, total)
    random.seed(args.seed)
    indices = sorted(random.sample(range(total), n))
    subset = ds.select(indices)

    out_root = Path(args.output_dir)
    src_dir = out_root / "src"
    oracle_dir = out_root / "oracle"
    src_dir.mkdir(parents=True, exist_ok=True)
    oracle_dir.mkdir(parents=True, exist_ok=True)

    written = {}
    manifest = []
    oracle_rows = []

    def write_snippet(snippet_id: int, code: str) -> str:
        if snippet_id in written:
            return written[snippet_id]
        sub = f"{snippet_id // 10000:04d}"
        d = src_dir / sub
        d.mkdir(parents=True, exist_ok=True)
        p = d / f"Snippet_{snippet_id}.java"
        p.write_text(wrap_java(snippet_id, code), encoding="utf-8")
        rel = str(p.relative_to(out_root))
        written[snippet_id] = rel
        manifest.append({"snippet_id": snippet_id, "file_path": rel})
        return rel

    for ex in subset:
        id1 = int(ex["id1"])
        id2 = int(ex["id2"])
        file1 = write_snippet(id1, ex["func1"])
        file2 = write_snippet(id2, ex["func2"])
        oracle_rows.append(
            {
                "pair_id": int(ex["id"]),
                "id1": id1,
                "id2": id2,
                "file1": file1,
                "file2": file2,
                "label": bool(ex["label"]),
            }
        )

    oracle_jsonl = oracle_dir / "oracle_pairs.jsonl"
    with oracle_jsonl.open("w", encoding="utf-8") as f:
        for row in oracle_rows:
            f.write(json.dumps(row) + "\n")

    oracle_csv = oracle_dir / "oracle_pairs.csv"
    with oracle_csv.open("w", encoding="utf-8") as f:
        f.write("pair_id,id1,id2,file1,file2,label\n")
        for row in oracle_rows:
            f.write(
                f"{row['pair_id']},{row['id1']},{row['id2']},{row['file1']},{row['file2']},{row['label']}\n"
            )

    ev = Path(args.evidence_dir)
    ev.mkdir(parents=True, exist_ok=True)
    (ev / "bcb_subset_manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    pos = sum(1 for r in oracle_rows if r["label"])
    neg = len(oracle_rows) - pos
    (ev / "bcb_subset_params.txt").write_text(
        "\n".join(
            [
                "dataset=google/code_x_glue_cc_clone_detection_big_clone_bench",
                f"split={args.split}",
                f"total_pairs_in_split={total}",
                f"subset_n={n}",
                f"seed={args.seed}",
                f"positive_pairs={pos}",
                f"negative_pairs={neg}",
                f"unique_snippets={len(written)}",
                "tool=ccaligner",
            ]
        )
        + "\n",
        encoding="utf-8",
    )

    print(f"Subset ready: pairs={len(oracle_rows)} unique_files={len(written)}")
    print(f"Oracle: {oracle_jsonl}")


if __name__ == "__main__":
    main()
