# Environment Setup Attempt - CCAligner
## Environment Baseline (CCAligner)

### Artifact-stated requirements
From the official CCAligner README:
- 64-bit Linux
- `g++`
- `flex`
- `libboost`

### Reproducibility container baseline
- Ubuntu 22.04
- OpenJDK 11
- Python 3 + pip
- build-essential, g++, make, flex, bison, libboost-all-dev
- FreeTXL (for extraction pipeline compatibility)

### Local paths
- Artifact: `tools/ccaligner_artifact`
- Logs: `evidence/logs`
- Generated work outputs: `out/`

### Notes
- CCAligner artifact includes Linux ELF binaries (`extract`, `parser`, `tokenize`, `detect`, `detect2`, `co1`).
- The upstream `runner` script has hardcoded `/home/wpc/...` paths; local scripts in `scripts/` replace this with repository-relative paths.
- A first Docker build attempt hit transient Ubuntu mirror `Hash Sum mismatch` errors during `apt-get install`; Dockerfiles now include apt retries (`Acquire::Retries=5`).