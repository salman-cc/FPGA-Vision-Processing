# Seminar study map

This repository documents Muhammed Salman C. C.'s course seminar, **FPGA-Based
Vision Processing for Autonomous Robots**.

The [main README](../README.md) is the full structured write-up. It is grounded
in the 40-slide verified seminar deck supplied by the author. The deck states
that this is a review, not an implementation.

## Topic provenance

<!-- markdownlint-disable MD013 -->
| Slides | Topic |
| --- | --- |
| 1-5 | Seminar identity, problem, objectives, scope |
| 6-13 | Robotic workloads, FPGA resources, CNN/YOLO, quantisation and metric equations |
| 14-17 | Motivation, evolution, survey examples |
| 18-21 | Li kernel partition, memory architecture, resources, results, timing caveat |
| 22-24 | Al Amin dataset, deployment, results |
| 25-30 | Comparative method, evidence limits, calculated efficiencies |
| 31-35 | Proposed robot, timing, energy, thermal behaviour, challenges, guidelines |
| 36-38 | Future directions and conclusions |
| 39-40 | Bibliography and discussion themes |
<!-- markdownlint-enable MD013 -->

## Evidence categories

- **Reported:** quantities quoted from the cited studies, not measurements made
  by the seminar author.
- **Derived:** arithmetic using those reported inputs, with their boundaries
  retained.
- **Proposed:** robot architecture and integration guidance synthesised from the
  literature, not a built prototype.

## Source consistency note

Slide 20 labels first-layer PE efficiency as 60.2%, while slide 19/20 gives 363
active PEs out of 600 convolution PEs. Direct division is 60.5%. The README
preserves the counts and states the mismatch instead of silently repeating the
percentage.

The older report recovered from prior correspondence is not included here as the
final submitted report. The newly supplied deck contains a fuller analysis and
is the primary source for this write-up.
