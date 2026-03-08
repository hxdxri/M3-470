# CloneWorks — Reproducibility Study

Reproducing CloneWorks clone detection on a BigCloneBench subset inside Docker.

## 1. Artifact

- **Paper**: "CloneWorks: A Fast and Flexible Large-Scale Near-Miss Clone Detection Tool" (ICSE 2017)
- **Authors**: Jeffrey Svajlenko, Chanchal K. Roy
- **Official repo**: https://github.com/jeffsvajlenko/CloneWorks
- **Fork used**: https://github.com/chutgiet/CloneWorks
- **Discovery notes**: [scripts/00_discover_artifact.md](scripts/00_discover_artifact.md)

> **Note**: The initial link to the tool provided in the paper was not working. The tool's repository was found through a Google search.

## 2. Environment

| Component      | Version / Value            |
|----------------|----------------------------|
| Base image     | `ubuntu:22.04`             |
| Java           | OpenJDK 11                 |
| Python         | Python 3                   |
| TXL            | FreeTXL 10.6+ (required)   |
| Build tools    | gcc, make (build-essential) |
| Extra Python   | datasets, pandas, numpy, scikit-learn, tqdm |

### Build the Docker image

```bash
cd cloneworks
docker build -t cloneworks:latest -f docker/Dockerfile .
```

### Start an interactive container

```bash
docker run --rm -it \
  -v "$PWD":/workspace \
  -v "$PWD/data":/workspace/data \
  -v "$PWD/out":/workspace/out \
  cloneworks:latest bash
```

### Capture environment info

Inside the container:
```bash
java -version > evidence/logs/env.txt 2>&1
python3 --version >> evidence/logs/env.txt 2>&1
cat /etc/os-release >> evidence/logs/env.txt 2>&1
```

## 3. Step-by-Step Reproducibility

### Step 1: Fetch the artifact

```bash
./scripts/01_fetch_artifact.sh
```

This clones the official CloneWorks repository into `tools/cloneworks_artifact/` and records the commit hash in `evidence/logs/artifact.txt`.

### Step 2: Smoke test

```bash
./scripts/20_smoke_test.sh
```

This compiles CloneWorks, compiles TXL grammars (if TXL is available), and runs cwbuild + cwdetect on the included JHotDraw example. Logs go to `evidence/logs/smoke_test.log`.

### Step 3: Prepare BigCloneBench subset

```bash
python3 scripts/10_prepare_bigclonebench_subset.py \
    --n 2000 --seed 42 \
    --output-dir data/bigclonebench_subset \
    --evidence-dir evidence/logs
```

This downloads BigCloneBench from HuggingFace, selects 2000 random pairs (seed=42), materializes Java snippets into `data/bigclonebench_subset/src/`, and writes an oracle to `data/bigclonebench_subset/oracle/`.

**Subset selection rule**: `random.sample(range(total_pairs), N)` with Python's `random` module, seed=42.

### Step 4: Run cwbuild

```bash
./scripts/30_run_cwbuild.sh data/bigclonebench_subset/src out/cwbuild type3token
```

Builds the feature database from source. Log: `evidence/logs/cwbuild.log`.

### Step 5: Run cwdetect

```bash
./scripts/40_run_cwdetect.sh out/cwbuild out/cwdetect config/cwdetect.conf
```

Runs clone detection with similarity threshold 0.7 (default, per paper recommendation for Type-3). Log: `evidence/logs/cwdetect.log`.

Override threshold: `SIMILARITY=0.5 ./scripts/40_run_cwdetect.sh ...`

### Step 6: Run cwformat (post-processing)

```bash
./scripts/50_run_cwformat.sh out/cwdetect out/cwformat
```

Converts raw clone output to JSONL/CSV with resolved file paths. Log: `evidence/logs/cwformat.log`.

### Step 7: Evaluate

```bash
python3 scripts/60_eval_bigclonebench.py \
    --oracle data/bigclonebench_subset/oracle/oracle_pairs.jsonl \
    --clones out/cwformat/clones_formatted.jsonl \
    --filemap out/cwbuild/bigclonebench.files \
    --results-dir results \
    --eval-dir out/eval
```

Computes precision, recall, and F1 against the oracle subset. Outputs:
- `results/cloneworks_metrics.json`
- `out/eval/metrics.json`
- `out/eval/false_positives_sample.json`
- `out/eval/false_negatives_sample.json`

## 4. Configuration

CloneWorks configurations are in `config/`:

| Config file              | Clone type | Description                                           |
|--------------------------|-----------|-------------------------------------------------------|
| `cwbuild_java_type2.conf`| Type-2    | Blind rename + literal abstraction, token join        |
| `cwbuild_java_type3.conf`| Type-3    | Token-level with operator/separator filtering         |

cwdetect uses CLI parameters (no config file). The similarity threshold is set via `-s` flag:
- **Type-1/2**: use `-s 1.0` with `--pre-sorted` flag
- **Type-3**: use `-s 0.7` (paper recommendation)

## 5. Interventions

| # | Intervention | Reason |
|---|-------------|--------|
| 1 | Used OpenJDK 11 instead of Java 7 | Java 7 is EOL; OpenJDK 11 is compatible |
| 2 | Used HuggingFace CodeXGLUE BigCloneBench | Original IJaDataset 2.0 is not easily downloadable; used HuggingFace datasets API to write custom scripts for pulling subsets |
| 3 | Subset to N=2000 pairs | Full benchmark has ~901K pairs; subsetting for feasibility |
| 4 | Pipeline orchestration scripts | CloneWorks has no evaluation pipeline; we added scripts for benchmark preparation, oracle comparison, and end-to-end orchestration |
| 5 | FreeTXL installation in Docker | TXL must be installed separately; Dockerfile handles setup |
| 6 | TXL lib path fix | TXL library path needed manual correction for the Docker environment |
| 7 | UTF-8 encoding flag | Added UTF-8 encoding flag to handle source files with non-ASCII characters |
| 8 | amd64 emulation for ARM | Docker required amd64 platform emulation when running on ARM-based Macs |

## 6. Outputs

| Output                        | Location                      |
|-------------------------------|-------------------------------|
| File ID mapping               | `out/cwbuild/bigclonebench.files` |
| Code fragments                | `out/cwbuild/bigclonebench.fragments` |
| Raw clone pairs               | `out/cwdetect/bigclonebench.clones` |
| Formatted clone pairs (JSONL) | `out/cwformat/clones_formatted.jsonl` |
| Formatted clone pairs (CSV)   | `out/cwformat/clones_formatted.csv` |
| Evaluation metrics            | `results/cloneworks_metrics.json` |

## 7. Results and Comparison to Paper

### Paper-reported results (ICSE 2017)

The CloneWorks paper reports using BigCloneBench and achieving:
- **Type-3 (conservative, threshold 0.7)**: Precision ~90–95%, Recall ~80–90%
- High scalability: millions of code fragments processed

### Our results

See `results/cloneworks_metrics.json` for computed precision, recall, and F1.

**Discussion**: Low recall is expected given the subset composition and evaluation approach. Results may diverge from the paper because:
1. We use a random subset (N=2000 pairs) rather than the full benchmark
2. The CodeXGLUE version of BigCloneBench may differ slightly from the original
3. Clone type distribution in the subset may differ from the full benchmark

## 8. TES Classification

**TES B** — Executable with intervention.

**Justification**: CloneWorks runs end-to-end on the BigCloneBench subset inside Docker, but requires:
- TXL installation (not bundled, must be separately obtained)
- Java version update (7 → 11)
- Wrapper scripts for benchmark preparation and evaluation
- Subsetting the benchmark for feasibility

If TXL cannot be installed → downgrade to **TES C** (partially executable: compilation works but cwbuild fails without TXL).

## 9. Repository Structure

```
cloneworks/
  README.md                          # This file
  Dockerfile                         # (legacy location, see docker/)
  docker/
    Dockerfile                       # System prompt Dockerfile
    entrypoint.sh
  config/
    cwbuild_java_type2.conf
    cwbuild_java_type3.conf
    cwdetect.conf
  scripts/
    00_discover_artifact.md
    01_fetch_artifact.sh
    10_prepare_bigclonebench_subset.py
    20_smoke_test.sh
    30_run_cwbuild.sh
    40_run_cwdetect.sh
    50_run_cwformat.sh
    60_eval_bigclonebench.py
  tools/
    cloneworks_artifact/             # Cloned official artifact
  data/                              # gitignored
    bigclonebench_subset/
      src/
      oracle/
  out/                               # gitignored
    cwbuild/
    cwdetect/
    cwformat/
    eval/
  evidence/
    logs/
    screenshots/
  results/
    cloneworks_metrics.json
    cloneworks_notes.md
    reproducibility_table.csv
```

## 10. Evidence

| Evidence | Location |
|----------|----------|
| Artifact provenance | `evidence/logs/artifact.txt` |
| Environment details | `evidence/logs/env.txt` |
| Smoke test log | `evidence/logs/smoke_test.log` |
| cwbuild log | `evidence/logs/cwbuild.log` |
| cwdetect log | `evidence/logs/cwdetect.log` |
| cwformat log | `evidence/logs/cwformat.log` |
| Subset manifest | `evidence/logs/bcb_subset_manifest.json` |
| Subset parameters | `evidence/logs/bcb_subset_params.txt` |
