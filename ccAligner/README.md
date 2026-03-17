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
| Smoke Test | Completed in Docker (log captured) |
| Benchmark Reproduction | First BigCloneBench subset attempt completed |
| Evaluation Workflow | Simplified to sampled-pair oracle only |
| TES Classification | TES-B (final) |

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
python3 scripts/10_prepare_bigclonebench_subset.py --n 200 --seed 42
./scripts/30_run_ccaligner_benchmark.sh
python3 scripts/60_eval_bigclonebench.py \
  --oracle data/bigclonebench_subset/oracle/oracle_pairs.jsonl \
  --clones out/ccaligner/clones.csv
```

Or via container:

```bash
docker build --no-cache --platform linux/amd64 -t ccaligner:amd64 -f docker/Dockerfile .
docker run --rm --platform linux/amd64 \
  -e BCB_N=200 \
  -v "$PWD":/workspace ccaligner:amd64
```

Important: if `-v "$PWD":/workspace` is omitted, logs/outputs are written only inside the temporary container filesystem and disappear on exit.

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
    10_prepare_bigclonebench_subset.py
    20_smoke_test.sh
    30_run_ccaligner_benchmark.sh
    60_eval_bigclonebench.py
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
- Benchmark run log: `evidence/logs/ccaligner_benchmark.log`
- BigCloneBench subset params: `evidence/logs/bcb_subset_params.txt`
- Evaluation mismatch and fix log: `EVALUATION_MISMATCH_LOG.md`
- Final sampled-oracle metrics: `results/ccaligner_metrics.json`
- Docker build attempt log: `evidence/logs/docker_build_attempt_2026-03-12.txt`
- Environment capture: `evidence/logs/env.txt` (next run)

## 8. Notes

Current evaluation is intentionally simple:
- sample labeled pairs from the HuggingFace BigCloneBench split,
- materialize the snippets referenced by those pairs,
- run CCAligner on the materialized snippet set,
- score only exact sampled oracle pairs,
- record any additional detections as unscored rather than expanding the oracle.

BigCloneEval requires the full BigCloneBench dataset and metadata structure, which is not included in the CodeXGLUE BigCloneBench pairs used in this study. Reconstructing the full benchmark environment would require materializing tens of thousands of methods and running a much larger evaluation pipeline than feasible within the available Docker environment on a 16 GB Mac. Therefore, this study uses a sampled labeled subset with a direct oracle comparison to keep the workflow reproducible and executable within the available computational resources. This simplified evaluation still demonstrates successful execution of CCAligner and verifies the clone detection workflow.

### Final reported evaluation (sample=2000)
- Sampled pairs: 2000 (positive 958, negative 1042)
- Detected pairs: 7805
- Scored detected pairs: 8
- True positives: 8, false positives: 0, false negatives: 950
- Precision: 1.0, Recall: 0.0084, F1: 0.0166

### Final conclusion
- Precision is artificially high due sampled-label scoring; most detections are unscored because they fall outside sampled pairs. So precision was not reproducable. 
- Recall is low because only a tiny part of the positive sampled oracle was recovered.
- This is mathematically expected with limited sampled oracle and a large dataset (BCB train/valid/test have hundreds of thousands of pair entries).
- Full-dataset evaluation in Docker with `--full-dataset-split train` was attempted but could not complete on 16GB Mac due CPU/IO/memory constraints.
- A robust next step would be chunked streaming (e.g. 100k pair chunks) with periodic progress and on-disk pair lookups.

## 9. NiCad iHotDraw Lightweight BigCloneEval Validation

We performed a lightweight validation run using NiCad iHotDraw (application subset) with CCAligner in Docker and BigCloneEval tooling:

1. Ran CCAligner benchmark in Docker against: `data/ihotdraw/nicad/NiCad-6.2/examples/JHotDraw/application`.
2. CCAligner generated `out/ccaligner_ihotdraw_app/clones.csv` with 8 clone pairs.
3. Converted CCAligner CSV to BigCloneEval import format and imported into BigCloneEval tool ID 1:
   - `application,DrawApplication.java,...` as synthetic subdirectory mapping.
4. BigCloneEval tool registration and import succeeded (`8` clones imported).
5. Evaluate step failed due missing BigCloneBench DB: `bigcloneeval/bigclonebenchdb/bcb` not found.

This confirms the end-to-end cloning pipeline works from CCAligner extraction to BigCloneEval import for lightweight test data, and highlights a dataset dependency needed for full recall evaluation.

### 9.1 NiCad + JHotDraw + BigCloneEval + era BCB Attempt

We also attempted a more complete validation on NiCad’s JHotDraw with the era BCB reduced BigCloneBench dataset. The goal was to reuse the same workflow as the lightweight app subset, but with a real BigCloneBench dataset in `bigcloneeval/bigclonebenchdb`.

Steps executed:
1. Prepare NiCad JHotDraw source:
   - `cd ccAligner && ./scripts/10_prepare_bigclonebench_subset.py --n 200 --seed 42` (for earlier BCB subset preparation)
   - For JHotDraw, we used local NiCad clone extraction directories from `data/ihotdraw/nicad/NiCad-6.2/examples/JHotDraw/`
2. Run CCAligner clone pipeline for full JHotDraw and convert to BCEval format:
   - `bash scripts/70_run_bigcloneeval_jhotdraw.sh`
3. Ensure era BCB dataset is downloaded and placed under BigCloneEval DB folder:
   - expected DB file: `ccAligner/bigcloneeval/bigclonebenchdb/bcb.mv.db` or `bcb.h2.db`
   - warning is shown if missing (evaluation cannot run)
4. Register tool and import clones:
   - `cd ccAligner/bigcloneeval/commands`
   - `./registerTool -n "CCAligner-JHotDraw" -d "CCAligner run on NiCad JHotDraw full example"`
   - `./importClones -t 1 -c ../out/ccaligner_ihotdraw_full/clones_bceval.csv`
5. Attempt evaluation:
   - `./evaluateTool -t 1 -o ../out/ccaligner_ihotdraw_full/bceval_evaluate.txt`

Observed result:
- The tool registration and import steps completed successfully.
- `evaluateTool` returned exit code 255 when DB file wasn’t present.
- After placing the era BCB h2 DB file in `bigcloneeval/bigclonebenchdb`, evaluation was interrupted (era subset was too large for processing) and output report generation failed.

Key note:
- This run demonstrates a reproducible NiCad + JHotDraw + BigCloneEval end-to-end attempt when era BCB DB is available.
- The only blocker for full recall metrics is the presence and correct path of the BigCloneBench H2 DB files, as I used an outdate era reduced file.

### Citations
  Pengcheng Wang, Jeffrey Svajlenko, Yanzhao Wu, Yun Xu, and Chanchal K. Roy. 2018. CCAligner: a token based large-gap clone detector. In ICSE ’18: 40th International Conference on Software Engineering, May 27–June 3, 2018, Gothenburg, Sweden. ACM, New York, NY, USA, 12 pages. https://doi.org/10.1145/3180155.3180179
  
Jeffrey Svajlenko, Judith F. Islam, Iman Keivanloo, Chanchal K. Roy, and Mohammad Mamun Mia. 2014. Towards a Big Data Curated Benchmark of Inter-Project Code Clones. In 2014 IEEE International Conference on Software Maintenance and Evolution (ICSME). IEEE, 476–480.

Wenhan Wang, Ge Li, Bo Ma, Xin Xia, and Zhi Jin. 2020. Detecting Code Clones with Graph Neural Network and Flow-Augmented Abstract Syntax Tree. In 2020 IEEE 27th International Conference on Software Analysis, Evolution and Reengineering (SANER). IEEE, 261–271.

