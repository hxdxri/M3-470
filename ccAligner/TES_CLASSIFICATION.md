# TES Classification - CCAligner

## Final status
- **TES category**: TES-B
- **Final basis**: Artifact reproduced and executed successfully in Docker after resolving compatibility/dependency issues and documenting evaluation constraints. Subset evaluation runs completed and metrics generated; full dataset streaming was attempted and carefully documented as infeasible in this environment.

## Completed verification
- Smoke test run in Docker: success.
- BigCloneBench subset generation (n=2000): success.
- CCAligner detection pipeline run: success.
- Evaluation metrics generation: success.

## Final assessment of issues
- **Full-dataset streaming failure**: Running `scripts/60_eval_bigclonebench.py --full-dataset-split train` in Docker hung due high CPU/I/O on 16GB Mac.
- **Precision/recall evaluation semantics**:
  - Sampled oracle positive pairs: 958
  - Detected scored positives: 8
  - Precision (scored pairs): 1.0 (8 TP, 0 FP)
  - Recall: 0.0084 (8 TP of 958 positives)
  - Most detected pairs are unscored because they are outside the sampled oracle set.
- **Data scale factor**: BigCloneBench train split has ~900k pairs, validation/test ~415k each. Full-scale direct evaluation is not feasible in this local Docker environment.

## Final conclusion
The reproducibility workflow is complete for the subset evaluation. For final paper-level evaluation, the next step is to implement chunked streaming and BigCloneEval-style pair-level labeling on a larger compute environment.
