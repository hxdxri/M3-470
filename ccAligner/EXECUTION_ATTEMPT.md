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

## Next Execution Step
Run and capture:
1. `scripts/20_smoke_test.sh`
2. BigCloneBench subset preparation
3. CCAligner benchmark run and result parsing
4. Comparative reporting vs paper

## Benchmark Attempt (Completed)
Date: March 12, 2026

Pipeline run (Docker, mounted workspace):
- `docker run --rm --platform linux/amd64 -e BCB_N=100 -e BCB_SEED=42 -v "$PWD":/workspace ccaligner:amd64`

Artifacts produced:
- `evidence/logs/bcb_subset_params.txt`
- `evidence/logs/ccaligner_benchmark.log`
- `out/ccaligner/function.file`
- `out/ccaligner/clones.csv`
- `results/ccaligner_metrics.json`
- `out/eval/metrics.json`

Observed metrics for first attempt:
- Oracle pairs: 100 (50 positive, 50 negative)
- Detected pairs: 26
- True positives: 0
- False positives: 0
- False negatives: 50
- Unknown detected pairs (not part of selected oracle pair set): 26
- Labeled detection coverage: 0.0 (none of the 26 detected pairs are in sampled oracle pair list)

Interpretation:
- Execution is working end-to-end.
- Current sampled-pair oracle scope and detector output scope are misaligned.
- Precision/recall formulas are standard and correct, but paper-comparable values require a benchmark setup aligned with BigCloneEval semantics.
