# Boreas — Reproducibility Assessment

---

## 1. Artifact Discovery

The Boreas paper was reviewed for any links to source code, binaries, or replication packages. **No artifact link was provided in the paper.** A manual search was also conducted on GitHub and Google using queries such as "Boreas code clone detection tool", "Boreas source code", and related terms. None of these searches returned a usable artifact or repository.

**Conclusion:** The official artifact is unavailable.

---

## 2. Environment Setup

Not applicable — no artifact was found to install or configure.

---

## 3. Installation and Execution Steps

Not applicable — since no source code, binary, or container image is available, no installation or execution could be attempted.

---

## 4. Clone Types

The paper's findings demonstrate effectiveness on **Type-3 clones** specifically. By implication, the tool is expected to also detect **Type-1** and **Type-2** clones, as Type-3 detection subsumes these simpler clone types.

---

## 5. Benchmarks Used

The paper **did not use any standard benchmarks** (e.g., BigCloneBench, SemanticCloneBench, GPTCloneBench, Google Code Jam, or CLCDSA). Instead, the authors evaluated Boreas on their own datasets:

- **JDK 7** source code
- **Linux kernel 2.6.38.6** source code

No benchmark-based evaluation could be reproduced.

---

## 6. Reported Metrics

- **Precision / False Positive Rate:** The paper only highlighted a false positive rate of **< 5%**, estimated from 100 sampled clone pairs.
- **Recall:** Not reported.
- **Accuracy:** Not reported.

No standard recall or accuracy metrics were provided — only the sampled false-positive estimate.

---

## 7. Interventions Performed

No interventions were possible since the artifact was never obtained.

---

## 8. TES Classification

| Field | Value |
|---|---|
| **Tool** | Boreas |
| **Artifact** | N/A (artifact unavailable) |
| **Environment** | N/A (artifact unavailable) |
| **TES Category** | **TES-D: Non-Executable** |

### Justification

The tool is classified as **TES-D (Non-Executable)** because:

1. The paper did not include any artifact link.
2. Google and GitHub searches did not yield any artifact.
3. Without an artifact, no environment setup, execution, or benchmark evaluation could be performed.
4. The paper's own evaluation used private datasets (JDK 7 and Linux kernel source) rather than standard benchmarks, and reported only a sampled false-positive rate — not recall or accuracy.

**Not reproducible — tool artifact unavailable.**