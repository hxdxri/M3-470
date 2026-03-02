### Artifact Discovery
- Paper: https://arxiv.org/pdf/1512.06448

- Official artifact: https://github.com/Mondego/SourcererCC

- Discovery method: Located the tool by searching the tool name “SourcererCC” on google, the top result was the Mondego maintained GitHub repository.

- Verification: The repository name and documentation indicate it is the SourcererCC clone detector described in the paper and it is maintained by the same person/lab.

### Environmental Setup (dockerized)
- Host: Windows 10
- Container: Ubuntu 22.04
- Java: OpenJDK 11
- Python: Python 3.10
- Build tool: Apache Ant (installed in container)

- Further Proof
root@b544a82ef93f:/workspace# python3 --version
Python 3.10.12
root@b544a82ef93f:/workspace# java -version
Picked up JAVA_TOOL_OPTIONS: -Dfile.encoding=UTF-8
openjdk version "11.0.30" 2026-01-20
OpenJDK Runtime Environment (build 11.0.30+7-post-Ubuntu-1ubuntu122.04)OpenJDK 64-Bit Server VM (build 11.0.30+7-post-Ubuntu-1ubuntu122.04, mixed mode, sharing)
root@b544a82ef93f:/workspace# ls
LICENSE    WebApp          dockerfile        scripts-data-analysis
README.md  clone-detector  requirements.txt  tokenizers

### Installation and Execution Steps
1. Prerequisites (No local Java or Python installation is required)
  - Docker Desktop installed
  - Linux containers enabled (enabled by default in docker)

2. Clone the My team's Repository 
  '''
    https://github.com/hxdxri/M3-470.git

  '''

3. Clone the Tools Repository 
  - In the "SourcererCC" Folder of My team's repository, run:
  '''
    cd SourcererCC
    git clone https://github.com/Mondego/SourcererCC.git

  '''

4. Build the Docker Image (creates an Ubuntu 22.04 environment with OpenJDK 11, Python 3.10, Apache Ant)
  - From the root of the SourcererCC directory:
  '''
    docker build -t sourcerercc .

  '''

5. Start the Container
  - Run
  '''
    docker run --rm -it -v ${PWD}:/workspace sourcerercc bash

  '''

## Smoke Test Execution
6a. Smoke test input creation
  - Create a minimal Java project inside the container:
  '''
    mkdir -p miniproj

    cat > miniproj/Hello.java << 'EOF'

    public class Hello {
        public static void main(String[] args) {
            System.out.println("hi");
        }
    }
    EOF

  '''

  - Zip the project:
  '''
    zip -r miniproj.zip miniproj

  '''
  
  - Create a project-list.txt file containing the absolute path to the zip file:
  '''
    echo "/workspace/tokenizers/file-level/miniproj.zip" > project-list.txt

  '''

  - Ensure "SourcererCC\tokenizers\file-level\config.ini" contains:
  '''
    File_extensions = .java
    
  '''


6b. Run Tokenizer
  - Inside the container:
  '''
    cd tokenizers/file-level

    rm -rf bookkeeping_projs files_stats files_tokens logs

    python3 tokenizer.py zip 2>&1 | tee /workspace/SourcererCC/logs/tokenizer_smoketest.log

  '''

7. Prepare Dataset for Clone Detector
  '''
    cat files_tokens/* > blocks.file

    cp blocks.file /workspace/clone-detector/input/dataset/

  '''

8. Run Clone Detector
  - Still inside the container:
  '''
    cd /workspace/clone-detector

    rm -f scriptinator_metadata.scc Log_*.out Log_*.err

    rm -rf NODE_*

    python3 controller.py 2>&1 | tee /workspace/SourcererCC/logs/clone_detector_smoketest.log

  '''

Expected output: SUCCESS: Search Completed on all nodes

9. Aggregate Results
  '''
    cat NODE_*/output8.0/query_* > results.pairs

    wc -l results.pairs

  '''

### Benchmark used
- BigCloneBench (HuggingFace CodeXGLUE version)

- Subset size (20 pairs) 

- Default settings (80% threshold unless changed)


### Intervention
- The tool's README does not include a sample project to test with, so I created a small Java project and project-list.txt file in order to run the smoke test successfully.

- Installed "ant" because runnodes.sh relies on Ant build (build.xml) and init failed without it.

- Installed "python-is-python3" because scripts call python but Ubuntu 22.04 only provides python3 by default.

- Converted .sh files from CRLF to LF using "dos2unix" (Windows clone issue).


### Execution Outcome and TES Classification

SourcererCC was successfully executed end to end inside a Dockerized Ubuntu 22.04 environment using Java 11 and Python 3. The tool was run on a small BigCloneBench subset (20 pairs - used this because device couldn't handle more than 100 pairs without crashing) using default configuration settings (80% similarity threshold). The pipeline completed successfully, producing clone pair outputs and execution logs without runtime errors after environment setup.

However, the tool required several environment interventions to run correctly, including installation of Ant (for building Java components), the `python-is-python3` alias (required by legacy scripts), `dos2unix` (to normalize shell script line endings), and `zip` (for dataset packaging). These dependencies were not clearly documented in the official README and had to be identified during reproduction. All required fixes have been captured in the provided Dockerfile to ensure reproducible execution on first run.

Based on the taxonomy provoded, SourcererCC is classified as TES-B (Executable with Intervention), as it runs successfully but required some environment adjustments beyond the provided documentation.