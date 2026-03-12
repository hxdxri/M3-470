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
- Log: `evidence/logs/smoke_test.log`.
- Next action: run smoke test inside Docker image.

## Next Execution Step
Run and capture:
1. `scripts/20_smoke_test.sh`
2. BigCloneBench subset preparation
3. CCAligner benchmark run and result parsing
4. Comparative reporting vs paper
