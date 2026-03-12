# CCAligner Benchmark Notes (First Attempt)

Date: 2026-03-12

Run configuration:
- Subset source: BigCloneBench (CodeXGLUE train split)
- Subset size: 100 pairs (seed 42)
- CCAligner params: window=6, edit-distance=1, similarity=0.6

Produced files:
- `out/ccaligner/function.file`
- `out/ccaligner/clones.csv`
- `results/ccaligner_metrics.json`

Current result:
- End-to-end run succeeded (subset prep -> detector run -> evaluator output).
- Metrics show `precision=0, recall=0` with `unknown_detected=26`.

Reason for current mismatch:
- The current evaluator compares detector pairs against selected oracle pairs only.
- CCAligner reports additional pairs among materialized snippets not present in the selected pair list, so they are counted as `unknown_detected`.

Next refinement:
- Improve evaluator mapping/labeling policy for "unknown" pairs so reported precision/recall aligns with benchmark subset semantics.
