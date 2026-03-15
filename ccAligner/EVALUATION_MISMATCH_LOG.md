# CCAligner Evaluation Mismatch Log

This file tracks the mismatch issue, the unsuccessful fixes, and the simplified evaluation that replaced them.

## Stage 1: Initial sampled-pair evaluation
- Oracle: `oracle_pairs.jsonl` from the HuggingFace BigCloneBench split.
- Process: sample labeled pairs, materialize the referenced snippets, run CCAligner, compare detected pairs against sampled labels.
- Result: `detected_pairs=26`, but none of the 26 matched the exact sampled oracle pairs.

## Stage 2: What this actually means
- The file mapping is not obviously broken.
- The detected file paths in `out/ccaligner/clones.csv` point to snippet files created from the sampled dataset subset.
- The mismatch is at the pair level, not the snippet level:
  - sampled oracle labels a specific set of 100 pairs,
  - CCAligner can still report different pairings among the same sampled snippet pool.

## Stage 3: Overcomplicated fix attempt
- An induced oracle was generated over the selected snippet IDs.
- This created extra files and a second evaluation mode:
  - `oracle_pairs_induced.jsonl`
  - `oracle_pairs_induced.csv`
  - extra metrics JSON files
- This made the reporting harder to trust and harder to explain.
- The user also observed repeated induced entries and misleading totals. That path has now been removed.

## Stage 4: Simplified replacement
- The workflow now uses one oracle only: `oracle_pairs.jsonl`.
- Evaluation now reports:
  - `detected_pairs`
  - `scored_detected_pairs`
  - `unscored_detected_pairs`
  - `true_positives`
  - `false_positives`
  - `false_negatives`
  - `precision`
  - `recall`
  - `f1`
- Any detected pair not present in the sampled oracle is recorded as unscored, not re-labeled through an expanded oracle.

## Stage 5: Why paper values are still not reproduced
- The paper used BigCloneBench together with BigCloneEval and other benchmark procedures.
- The current class workflow is a direct sampled-pair comparison without BigCloneEval.
- Because of that, paper-level precision and recall values are not expected from the current simplified pipeline.

## TA clarification note
- There is still uncertainty about whether the assignment requires BigCloneEval for final reporting.
- An email has been sent to the TAs requesting clarification.
- Until that answer arrives, the repository keeps the simplest executable evaluation path and documents its limitations explicitly.
