# CCAligner - Reproducibility Study

Reproducing CCAligner clone detection with milestone-style evidence capture.

## 1. Artifact

- **Paper**: "CCAligner: a token based large-gap clone detector" (ICSE 2018)
- **Official repo**: https://github.com/PCWcn/CCAligner
- **Discovery correction log**: `ARTIFACT_DISCOVERY.md`
- **Deadline extension communication log**: `DEADLINE_EXTENSION.md`

## 2. Current Status

| Category | Status |
|---|---|
| Official Artifact Found | Yes (`PCWcn/CCAligner`) |
| Artifact Cloned Locally | Yes (`tools/ccaligner_artifact/`) |
| Workflow Foundation | Complete (this step) |
| Smoke Test | Scripted, pending full evidence run |
| Benchmark Reproduction | Next phase |
| TES Classification | Pending reassessment |

## 3. Paper-Grounded Benchmark Targets

From the ICSE 2018 paper (`Paper.pdf`):
- **BigCloneBench + BigCloneEval** for general Type-1/2/3 recall assessment.
- **Mutation-Injection framework** for large-gap recall by gap size.
- **Real projects comparison** (Cook, Redis, PostgreSQL, Linux, JDK, OpenNLP, Maven, Ant) for precision/recall/F1 analysis.

Details and extracted setup notes are documented in `BenchmarksUsed-README.md`.

## 4. Environment Baseline

Planned runtime baseline:
- Amazon Corretto 17 base image (`amazoncorretto:17`, glibc-based)
- `g++`, `flex`, `make`, `libboost`
- Java 17 (from Corretto base image)
- Python 3 (subset prep + evaluation scripts; extra Python libs installed in benchmark phase)
- TXL tooling (used by CCAligner extraction stage)

Container files:
- `Dockerfile` (top-level)
- `docker/Dockerfile`
- `docker/entrypoint.sh`

## 5. Foundation Workflow (Scaffolded)

```bash
cd ccAligner
./scripts/01_fetch_artifact.sh
./scripts/20_smoke_test.sh
```

Or via container:

```bash
docker build --no-cache --platform linux/amd64 -t ccaligner:amd64 -f docker/Dockerfile .
docker run --rm --platform linux/amd64 \
  -v "$PWD":/workspace ccaligner:amd64
```

## 6. Directory Structure

```
ccAligner/
  README.md
  Paper.pdf
  Assignment-README.md
  BenchmarksUsed-README.md
  ARTIFACT_DISCOVERY.md
  DEADLINE_EXTENSION.md
  ENVIRONMENT.md
  EXECUTION_ATTEMPT.md
  TES_CLASSIFICATION.md
  config/
    ccaligner.env
  docker/
    Dockerfile
    entrypoint.sh
  scripts/
    00_discover_artifact.md
    01_fetch_artifact.sh
    20_smoke_test.sh
    run_full_pipeline.sh
  tools/
    ccaligner_artifact/
  data/                  # benchmark data (gitignored)
  out/                   # generated outputs (gitignored)
  evidence/
    logs/
    screenshots/
  results/
```

## 7. Evidence Index

- Artifact provenance: `evidence/logs/artifact.txt`
- Search correction log: `evidence/logs/search_attempts.txt`
- Smoke test log: `evidence/logs/smoke_test.log`
- Docker build attempt log: `evidence/logs/docker_build_attempt_2026-03-12.txt`
- Environment capture: `evidence/logs/env.txt` (next run)

## 8. Notes

This commit establishes the reproducibility foundation only.  
Full benchmark execution (BigCloneBench / BigCloneEval and mutation-framework emulation) is the next incremental phase.
