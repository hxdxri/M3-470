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
- Metrics show `precision_labeled_pairs_only=0`, `recall_sampled_positive_pairs=0`, with `unknown_detected=26`.

Reason for current mismatch:
- The sampled oracle contains labels for only the selected 100 pairs.
- CCAligner detects clones across all materialized snippets (198 files), and many detected pairs are outside that selected pair list.
- Those are counted as `unknown_detected`; they are not automatically false positives.

Next refinement:
- Build an induced oracle over selected snippets (or use official BigCloneEval on full BigCloneBench) to align detector output scope and oracle scope.
