SAGA - Evaluation Report



Discovery

Found at: https://github.com/FudanSELab/SAGACloneDetector
The authors linked their GitHub directly in the paper



Environment

\- Windows 11, Java 8

\- NVIDIA RTX 5050, CUDA 13.0



How to Run

1\. Clone the repo or use the JAR directly

2. Open config.properties and change `exe=executable/sa_gpu.exe` to `exe=executable/psacd_win10.exe`

3. Delete everything in `tokenData/` and `result/` folders before running

4\. Run: `java -jar SAGACloneDetector.jar <input\_folder> result`



Interventions Required

1\. The Default config uses `sa\_gpu.exe` but silently returns 0 results , switched to `psacd\_win10.exe` (CPU fallback, included in repo)

2\. Had to clear `tokenData` data before each run to avoid IndexOutOfBoundsException crash exception



Benchmark

BigCloneBench : 2000 pair subset, 2996 Java files, seed=42.
See data/subset_description.txt for full details.
Use scripts/prepare_bcb.py to regenerate the exact same subset.



Results

| Metric | Our Result | Paper Reported |

|--------|-----------|----------------|

| Precision | 0.0021 | 0.99 |

| Recall | 0.0010 | N/A (per clone type, Table IV) |

| Clone Types | Type-1, 2, 3 | Type-1, 2, 3 |





TES Classification: TES-E

Tool executed end-to-end and produced output, but results deviate substantially from the paper. 487 clone pairs detected with only 1 true positive. Likely because SAGA is designed for large multi-method codebases, not isolated single-method snippets as used in BigCloneBench subset evaluation.

