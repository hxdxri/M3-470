# Execution Attempt - CCAligner

## Prior Attempt (Superseded)
The prior attempt reported "not possible" because artifact discovery was incorrectly marked as unavailable.

## Correction
As of March 12, 2026, repository discovery has been corrected:
- https://github.com/PCWcn/CCAligner

## Foundation Step Completed
- Workflow scaffold added (`docker/`, `scripts/`, `config/`, `data/`, `out/`, `results/`, `evidence/`).
- Artifact cloned to `tools/ccaligner_artifact`.
- Repro scripts prepared:
  - `scripts/01_fetch_artifact.sh`
  - `scripts/20_smoke_test.sh`
  - `scripts/run_full_pipeline.sh`

## Current Smoke-Test Evidence
- `scripts/01_fetch_artifact.sh` executed and wrote `evidence/logs/artifact.txt`.
- `scripts/20_smoke_test.sh` executed on host and correctly aborted with Linux-only warning.
- Smoke test then executed successfully in Docker with workspace mount.
- Log: `evidence/logs/smoke_test.log`.
- Note: running container without `-v "$PWD":/workspace` discards logs after container exit.

## Execution status
All execution steps are completed for the reproducible subset workflow.

## Final Benchmark Attempt (Completed)
Date: March 15, 2026

Pipeline run (Docker, mounted workspace) for n=2000 sample:
- `docker run --rm --platform linux/amd64 -v "$PWD":/workspace ccaligner:amd64 bash -lc "cd /workspace && scripts/20_smoke_test.sh && python3 scripts/10_prepare_bigclonebench_subset.py --n 2000 --seed 42 && ./scripts/30_run_ccaligner_benchmark.sh && python3 scripts/60_eval_bigclonebench.py --oracle data/bigclonebench_subset/oracle/oracle_pairs.jsonl --clones out/ccaligner/clones.csv --results-dir results --eval-dir data/bigclonebench_subset/eval --metrics-name ccaligner_metrics_2000.json"`

Artifacts produced:
- `evidence/logs/bcb_subset_params.txt`
- `evidence/logs/ccaligner_benchmark.log`
- `out/ccaligner/function.file`
- `out/ccaligner/clones.csv`
- `results/ccaligner_metrics_2000.json`
- `data/bigclonebench_subset/eval/ccaligner_metrics_2000.json`

Observed metrics for n=2000 sampled oracle:
- Oracle pairs: 2000 (958 positive, 1042 negative)
- Detected pairs: 7805
- Scored detected pairs: 8
- Unscored detected pairs: 7797
- True positives: 8
- False positives: 0
- False negatives: 950
- Precision: 1.0
- Recall: 0.0084
- F1: 0.0166
- Scored detection coverage: 0.001

Interpretation:
- Execution is working end-to-end.
- Only 8 detected pairs scored against sampled oracle; most detections are unscored because they are outside the sampled labeled subset.
- Precision is artificially high in sampled oracle mode; recall is low.
- Full-dataset streaming evaluation attempt with `--full-dataset-split train` failed due Docker resource constraints on 16GB Mac (CPU/I/O saturation).
- Evaluation remains a valid subset-based reproducibility result.

## Final next steps
- Keep this reproducible subset workflow as the final executable evaluation.
- For final large-scale assessment, implement chunked streaming evaluation with pair-level labeling on a larger compute environment, then compare with BigCloneEval.
