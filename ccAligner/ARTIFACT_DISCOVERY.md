# Artifact Discovery - CCAligner (Corrected)

## Paper Reference
Wang et al., *CCAligner: A Token-Based Large-Gap Clone Detector*, ICSE 2018.

Paper links reviewed:
- https://clones.usask.ca/pubfiles/articles/Wang_CCAlignerICSE2018.pdf
- https://ieeexplore.ieee.org/document/8453188/
- https://dl.acm.org/doi/10.1145/3180155.3180179
- https://conf.researchr.org/details/icse-2018/icse-2018-Technical-Papers/65/CCAligner-a-token-based-large-gap-clone-detector

## Initial Mistake (Why TES-D Was Incorrect)
My first artifact discovery pass incorrectly concluded that CCAligner had no public implementation.

Root causes:
- I relied heavily on Google search results and did not use GitHub's repository search directly.
- I relied too heavily on AI summaries of the paper and references, which repeatedly stated there was no repository link.
- I focused on whether the paper itself contained a direct artifact link, instead of searching author repositories by keyword.
- I also used/checked a misspelled keyword (`CCAlginer`) during part of search verification, which likely reduced discoverability.
- I suspect discoverability was further affected by the maintainer account name displaying Chinese characters (`PCWcn` / `王鹏程`), which I did not include in initial query patterns.

## Corrected Discovery Process
After teammate cross-checking, I re-ran discovery with GitHub-first search and found:

- Official artifact repository: https://github.com/PCWcn/CCAligner
- Owner profile: https://github.com/PCWcn (display name includes `王鹏程`)
- Repo description references ICSE 2018 implementation.

## Related but Unrelated Project
`saurabhshri/CCAligner` is an audio/subtitle alignment project and is not the ICSE 2018 clone detection tool.

## Status After Correction
- Previous "artifact unavailable" conclusion is withdrawn.
- CCAligner now proceeds to full reproduction workflow (environment, smoke test, benchmark, evaluation).
- TES classification is updated.
