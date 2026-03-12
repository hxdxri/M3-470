# Environment Setup Attempt - CCAligner
## Environment Baseline (CCAligner)

### Artifact-stated requirements
From the official CCAligner README:
- 64-bit Linux
- `g++`
- `flex`
- `libboost`

### Reproducibility container baseline
- Amazon Corretto 17 (`amazoncorretto:17`)
- Python 3 + pip
- gcc, gcc-c++, make, flex, bison, boost-devel
- FreeTXL (for extraction pipeline compatibility)

### Local paths
- Artifact: `tools/ccaligner_artifact`
- Logs: `evidence/logs`
- Generated work outputs: `out/`

### Notes
- CCAligner artifact includes Linux ELF binaries (`extract`, `parser`, `tokenize`, `detect`, `detect2`, `co1`).
- The upstream `runner` script has hardcoded `/home/wpc/...` paths; local scripts in `scripts/` replace this with repository-relative paths.
- Ubuntu mirror hash issues were blocking builds in this environment; Dockerfiles were migrated to `amazoncorretto:17` + `yum` to avoid `apt` mirror instability while preserving glibc compatibility.
- Python benchmark libraries (`datasets`, `pandas`, `numpy`, `scikit-learn`) are deferred to benchmark-stage setup instead of image build to keep base image stable.
