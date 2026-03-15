SAGA - Evaluation Report



Discovery

Found at: https://github.com/FudanSELab/SAGACloneDetector.
Searched "SAGA clone detection git" on google search and came across the autors git repo
The authors linked their GitHub directly in the README



Environment

- Windows 11, Java 8

- NVIDIA RTX 5050, CUDA 13.0


Step 1 - Clone Repo and basic check
First thing I did was just run the JAR to make sure it responds:

git clone https://github.com/FudanSELab/SAGA
java -jar SAGACloneDetector.jar

Got back the version and usage info. 

Step 2 - First real run
I then created two small Java test files and ran the tool. It immediately crashed:

Exception in thread "main" java.lang.IndexOutOfBoundsException: Index: 2, Size: 2
    at com.company.format.Printer.printMeasureIndex(Printer.java:81)
    at com.company.Tokenizer.tokenize(Tokenizer.java:192)

No useful error message at all. After looking around I found the `tokenData/` 
folder had leftover files from a previous run on the machine. The tool was 
loading unused cached data and crashing. Nothing in the docs warns about this.

Fix: Clear tokenData and result before every run:

Remove-Item tokenData\* -Recurse -Force
Remove-Item result\* -Recurse -Force


### Step 3 - After clearing cache
Ran again after clearing. No crash this time but got:

total token num is: 0
total measure num is: 0
no measure extracted from dataset!

My test files were too small - just a single 3-line method each. SAGA needs 
methods with at least 50 tokens to process them (mlc=50 in config.properties).

Step 4 - Built-in testcases
Tried the Java testcases included in the repo:

java -jar SAGACloneDetector.jar testcase\code\java result

Tool ran the full pipeline but returned:

result group: 0
Zero clones. This is where I got confused cause the tool ran but found nothing. 
I spent time trying to figure out why before I realized it was a GPU issue.

Step 5: Figuring out the GPU problem
The tool was calling `sa_gpu.exe` but was not getting nothing back. I checked 
`logs/saga.log` which had the authors' own test runs  still on the 
machine. Their runs used a completely different executable:

./executable/psacd_win10 → result group: 41
./executable/psacd_win10 → result group: 166

The authors used the CPU executable for their own Windows tests, not the GPU one.

After reading the official documentation more carefully, I found that `sa_gpu.exe` 
needs to be compiled from source for your specific CUDA version:

nvcc -o executable/sa_gpu scripts/suffix-construct.cu

The prebuilt exe in the repo was compiled for CUDA 12.4. My machine has CUDA 13.0. 
That caused sa_gpu.exe to silently return 0 results with no error .

Fix: Changed one line in config.properties:

from: exe=executable/sa_gpu.exe   →   to:exe=executable/psacd_win10.exe

psacd_win10.exe is the CPU fallback included in the repo. Same algorithm, no GPU, 
but it actually works.

Step 6  Working run
After the exe fix, ran on the built-in testcases:

result group: 4

Finally getting real output.


How to Run

1\. Clone the repo or use the JAR directly

2. Open config.properties and change `exe=executable/sa_gpu.exe` to `exe=executable/psacd_win10.exe`

3. Delete everything in `tokenData/` and `result/` folders before running

4\. Run: `java -jar SAGACloneDetector.jar <input\_folder> result`



Interventions Required

1\. The Default config uses `sa\_gpu.exe` but silently returns 0 results , switched to `psacd\_win10.exe` (CPU fallback, included in repo)

2\. Had to clear `tokenData` data before each run to avoid IndexOutOfBoundsException crash exception



Benchmark

Used a 2000-pair random subset. Generated the subset using `scripts/prepare_bcb.py`:

python scripts/prepare_bcb.py --n 2000 --seed 42 --output-dir bigclonebench_subset


Subset breakdown:
- 2000 oracle pairs
- 2996 unique Java files  
- 958 true clone pairs, 1042 non-clone pairs
- Seed fixed at 42 so results are reproducible

Then ran SAGA:

Remove-Item tokenData\* -Recurse -Force
Remove-Item result\* -Recurse -Force
java -jar SAGACloneDetector.jar bigclonebench_subset\src result


Output:
2996 files have been loaded
total token num is: 729589
total measure num is: 2885
result group: 179
total time cost: PT3.553S


179 clone groups, 487 clone pairs detected in under 4 seconds.

Settings used:all default except the exe:

threshold=0.7, mlc=50, min-line=2, granularity=method, language=java
exe=executable/psacd_win10.exe


Results

| Metric | Our Result | Paper Reported |

|--------|-----------|----------------|

| Precision | 0.0021 | 0.99 |

| Recall | 0.0010 | N/A (per clone type, Table IV) |

| Clone Types | Type-1, 2, 3 | Type-1, 2, 3 |

The numbers are way off from the paper. SAGA was built very large codebases . It finds clones by detecting repeated token sequences across a big collection. BigCloneBench subset has 2996 files with one short method each. There isnt enough repetition for SAGA to work properly so it ends up matching methods that share common java boilerplate rather than real clones.



TES Classification: TES-E

Tool executed end-to-end and produced output, but results deviate substantially from the paper. 487 clone pairs detected with only 1 true positive. Likely because SAGA is designed for large multi-method codebases, not isolated single-method snippets as used in BigCloneBench subset evaluation.

