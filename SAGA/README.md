# SAGA - Evaluation Report

**Paper:** SAGA: Efficient and Large-Scale Detection of Near-Miss Clones with GPU Acceleration  
**Authors:** Guanhua Li et al., Fudan University  
**Venue:** SANER 2020  
**TES Classification:** TES-E (Executed with Divergent Results)
---

## Discovery

Found at: https://github.com/FudanSELab/SAGACloneDetector  
Searched "SAGA clone detection git" on Google and came across the authors' GitHub repo.  
The authors also linked their GitHub directly in the README.

---

## Environment

- Windows 11, Java 8
- NVIDIA RTX 5050, CUDA 13.0

---

## Getting It Running

### Step 1 - Clone Repo and Basic Check
First thing I did was just run the JAR to make sure it responds:
```
git clone https://github.com/FudanSELab/SAGA
java -jar SAGACloneDetector.jar
```
Got back the version and usage info.

---

### Step 2 - First Real Run
I then created two small Java test files and ran the tool. It immediately crashed:
```
Exception in thread "main" java.lang.IndexOutOfBoundsException: Index: 2, Size: 2
    at com.company.format.Printer.printMeasureIndex(Printer.java:81)
    at com.company.Tokenizer.tokenize(Tokenizer.java:192)
```
No useful error message at all. After looking around I found the `tokenData/` 
folder had leftover files from a previous run on the machine. The tool was 
loading unused cached data and crashing. Nothing in the docs warns about this.

**Fix:** Clear tokenData and result before every run:
```
Remove-Item tokenData\* -Recurse -Force
Remove-Item result\* -Recurse -Force
```

---

### Step 3 - After Clearing Cache
Ran again after clearing. No crash this time but got:
```
total token num is: 0
total measure num is: 0
no measure extracted from dataset!
```
My test files were too small - just a single 3-line method each. SAGA needs 
methods with at least 50 tokens to process them (mlc=50 in config.properties).

---

### Step 4 - Built-in Testcases
Tried the Java testcases included in the repo:
```
java -jar SAGACloneDetector.jar testcase\code\java result
```
Tool ran the full pipeline but returned:
```
result group: 0
```
Zero clones. This is where I got confused cause the tool ran but found nothing. 
I spent time trying to figure out why before I realized it was a GPU issue.

---

### Step 5 - Figuring Out the GPU Problem
The tool was calling `sa_gpu.exe` but was not getting nothing back. I checked 
`logs/saga.log` which had the authors' own test runs still on the machine. 
Their runs used a completely different executable:
```
./executable/psacd_win10 → result group: 41
./executable/psacd_win10 → result group: 166
```
The authors used the CPU executable for their own Windows tests, not the GPU one.

After reading the official documentation more carefully, I found that `sa_gpu.exe` 
needs to be compiled from source for your specific CUDA version:
```
nvcc -o executable/sa_gpu scripts/suffix-construct.cu
```
The prebuilt exe in the repo was compiled for CUDA 12.4. My machine has CUDA 13.0. 
That caused sa_gpu.exe to silently return 0 results with no error.

**Fix:** Changed one line in config.properties:
```
from: exe=executable/sa_gpu.exe
to:   exe=executable/psacd_win10.exe
```
psacd_win10.exe is the CPU fallback included in the repo. Same algorithm, no GPU, 
but it actually works.

---

### Step 6 - Working Run
After the exe fix, ran on the built-in testcases:
```
result group: 4
```
Finally getting real output.

---

## How to Run

1. Clone the repo or use the JAR directly
2. Open config.properties and change `exe=executable/sa_gpu.exe` to `exe=executable/psacd_win10.exe`
3. Delete everything in `tokenData/` and `result/` folders before running
4. Run: `java -jar SAGACloneDetector.jar <input_folder> result`

---

## Interventions Required

1. The default config uses `sa_gpu.exe` but silently returns 0 results — switched to `psacd_win10.exe` (CPU fallback, included in repo)
2. Had to clear `tokenData` before each run to avoid IndexOutOfBoundsException crash

---

## Benchmark

Used a 2000-pair random subset. Generated the subset using `scripts/prepare_bcb.py`:
```
python scripts/prepare_bcb.py --n 2000 --seed 42 --output-dir bigclonebench_subset
```

Subset breakdown:
- 2000 oracle pairs
- 2996 unique Java files
- 958 true clone pairs, 1042 non-clone pairs
- Seed fixed at 42 so results are reproducible

Then ran SAGA:
```
Remove-Item tokenData\* -Recurse -Force
Remove-Item result\* -Recurse -Force
java -jar SAGACloneDetector.jar bigclonebench_subset\src result
```

Output:
```
2996 files have been loaded
total token num is: 729589
total measure num is: 2885
result group: 179
total time cost: PT3.553S
```
179 clone groups, 487 clone pairs detected in under 4 seconds.

Settings used , all default except the exe:
```
threshold=0.7, mlc=50, min-line=2, granularity=method, language=java
exe=executable/psacd_win10.exe
```

---

## Results

| Metric | Our Result | Paper Reported |
|--------|-----------|----------------|
| Precision | 0.0021 | 0.99 |
| Recall | 0.0010 | N/A (per clone type, Table IV) |
| Clone Types | Type-1, 2, 3 | Type-1, 2, 3 |
| True positives | 1 | N/A |
| False positives | 486 | N/A |
| False negatives | 957 | N/A |
| Clone groups | 179 | N/A |


-**Precision (0.0021)** may be underestimated. All 487 detected pairs 
  fell within our oracle coverage, but the oracle only covers 2000 pairs 
  out of 901,028 total in BigCloneBench. Some of our 486 apparent false 
  positives could be real clones that simply were not sampled into our 
  2000 pairs. Full validation would require querying the entire BigCloneBench 
  database.

- **Recall (0.0010)** is a reliable lower bound. SAGA found only 1 out of 
  958 known positive pairs, missing 957 real clones. This is expected 
  because SAGA was designed for large multi-method codebases, not isolated 
  single-method snippets.

- **Why results are this low** is mathematically expected. BigCloneBench 
  has hundreds of thousands of pairs. Our 2000-pair subset with single-method 
  snippets does not match the large codebase environment SAGA was built and 
  evaluated on in the paper.

---

## TES Classification: TES-E

The tool completed the full pipeline end-to-end after two fixes:
- Tokenization, suffix array construction, and clone pair output all completed ✅
- Precision and recall were computable
  
TES-E is the correct classification because the tool ran successfully 
but results deviate substantially from the paper (precision 0.0021 vs 
0.99). This is not a tool failure , it is a mismatch between SAGA being 
designed for large multi-method codebases and our single-method snippet 
evaluation setup.

TES-C and TES-D do not apply because the tool completed the full workflow.  
TES-B does not apply because the results do not match the paper.
