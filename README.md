# CMPT 470 - Milestone 3
## Reproducibility Assessment of Code Clone Detection Tools

### Team: Tech Titans
This repository is the group record for our reproducibility assessment of assigned code clone detection tools.  
The goal is to evaluate artifact availability, executability, and result reproducibility, following the course protocol.

## Assignment Scope
For each assigned tool, we will:
1. Verify and document the official artifact.
2. Set up the required environment.
3. Run smoke tests and capture evidence.
4. Execute on approved benchmark(s) using default or paper-specified settings.
5. Assess outcomes and assign a TES category.

## Assigned Tools
This team is covering:
- CCAligner: Haidari Alhaidari
- SourcererCC: Ademola Obalaye
- Boreas: Giet, Chut
- CloneWorks: Giet, Chut
- SAGA: Emeka-Nwuba, Chibuikem
- LePalex: Olukuewu, Samuel


Tool-specific setup, execution steps, benchmark configuration, interventions, logs, and outcomes are documented in each tool's own section/README by the responsible teammate.

## Required Benchmarks
- BigCloneBench
- SemanticCloneBench
- GPTCloneBench
- Google Code Jam
- CLCDSA

Benchmarks are used as provided by the assignment guidelines (no dataset modification).

## TES Taxonomy (Required)
Each tool is classified with exactly one category:
- `TES-A`: Executable
- `TES-B`: Executable with Intervention
- `TES-C`: Partially Executable
- `TES-D`: Non-Executable
- `TES-E`: Executed with Divergent Results

## Reporting Rules
- Report results in the required standardized table format.
- Use `N/A` where a value cannot be reported, with justification in notes.
- Ensure every reported value is traceable to repository evidence (logs, scripts, outputs, screenshots).

## Repository Expectations
This repository includes:
- A top-level README (this file).
- Dedicated documentation/evidence for each assigned tool.
- Reproduction scripts/commands where applicable.
- Logs and error traces supporting claims.
- The completed results table (CSV or equivalent).

## Integrity and Reproducibility Principles
- Do not rewrite tool logic.
- Do not change algorithms or evaluation design.
- Do not tune beyond paper-described settings.
- Do not substitute datasets.
- Document all interventions and failures honestly.
- Cite all external sources used.
