# CCAligner Benchmark Notes

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
- Metrics are now interpreted only against the sampled oracle pairs.
- On the current 100-pair run, CCAligner produced 26 detected pairs, but none of them matched the exact sampled oracle pairs.

Reason for current mismatch:
- The sampled oracle contains labels for only the exact 100 selected pairs.
- CCAligner processes the full snippet pool materialized from those pairs and can return different pairings among the same snippets.
- Those extra detections are now treated as `unscored_detected_pairs` rather than as evidence for a second oracle.

Current position:
- The simplified workflow is easier to defend empirically: actual sampled labels vs observed exact-pair matches.
- It does not yet reproduce paper-style values.
- BigCloneEval may still be needed for a paper-faithful evaluation. Clarification has been requested from the TAs.
