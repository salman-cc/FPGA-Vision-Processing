# FPGA-Based Vision Processing for Autonomous Robots

My course seminar and literature study on FPGA-based vision processing for
autonomous robots.

This repository documents my literature review, comparative analysis, and design
synthesis on predictable, energy-aware vision processing at the robotic edge. It
studies how FPGA architecture, memory-aware dataflow, quantisation, and
hardware-software partitioning affect perception.

**Status:** completed seminar study, not a hardware implementation. The
published systems and measurements discussed below belong to the cited
researchers. I have not independently reproduced their experiments. The proposed
robot architecture is a design synthesis, not a tested prototype.

## Contents

- [Problem and scope](#problem-and-scope)
- [Technical foundations](#technical-foundations)
- [Three studies, three levels of
  analysis](#three-studies-three-levels-of-analysis)
- [Li et al.: memory-aware CNN
  acceleration](#li-et-al-memory-aware-cnn-acceleration)
- [Al Amin et al.: YOLO deployment on the Kria
  KV260](#al-amin-et-al-yolo-deployment-on-the-kria-kv260)
- [Comparative analysis](#comparative-analysis)
- [Proposed robot architecture](#proposed-robot-architecture)
- [Design guidelines and evidence
  limits](#design-guidelines-and-evidence-limits)
- [Research gaps and future scope](#research-gaps-and-future-scope)
- [Sources and repository contents](#sources-and-repository-contents)

## Problem and scope

A robot operates in a closed loop: sense, perceive, localise, plan, and act.
Camera images must become useful perception results before they are too old for
that loop. High arithmetic demand, repeated memory traffic, and competition for
shared resources make this a system problem rather than an inference-speed
problem alone.

The seminar asks: how can FPGA architecture, dataflow, quantisation, and
hardware-software co-design support predictable, energy-efficient robotic
vision?

The scope is edge inference and its integration with robot software. Cloud
processing and mechanical design are outside the review. The work covers:

1. Vision, convolutional neural networks (CNNs), and YOLO computation.
2. FPGA resources and their relevance to real-time robotics.
3. Li et al.'s kernel-partition accelerator and memory organisation.
4. Al Amin et al.'s Kria deployment flow.
5. Comparisons that keep unlike metrics separate.
6. Benchmarking, memory, timing, reliability, and reproducibility gaps.

## Technical foundations

### FPGA resources and the hardware-software split

<!-- markdownlint-disable MD013 -->
| Resource | Role in the study |
| --- | --- |
| Lookup tables and flip-flops | Custom datapaths, control, registers, pipeline stages |
| DSP blocks | Multiply-accumulate (MAC) computation |
| Block RAM (BRAM) | Local buffers, feature maps, and weights |
| External memory | Data that cannot remain on chip |
| Arm processor cores on SoC platforms | Coordination, runtime software, decoding, and robot-level functions |
<!-- markdownlint-enable MD013 -->

Regular pixel and tensor operations can run in parallel or as streaming
pipelines. Local reuse matters because more processing elements (PEs) are useful
only if the memory system can supply their operands. Processors retain less
regular coordination work.

CNN convolution applies learned filters to image windows. Its work grows with
resolution, channels, and depth. YOLO performs single-stage detection; its
outputs still require decoding, confidence filtering, and non-maximum
suppression (NMS). A compact model does not remove these surrounding costs.

### Quantisation

The deck explains a generic affine integer mapping:

```text
q = clip(round(x / s) + z, q_min, q_max)
x_hat = s * (q - z)
```

Here `s > 0` is the scale and `z` is the integer zero point. This is a
conceptual example, not a claim about the exact DPU quantisation profile.
Calibration and suitable accumulator width matter, and converted-model quality
needs evaluation.

### Metrics must remain separate

<!-- markdownlint-disable MD013 -->
| Metric | Meaning | Important distinction |
| --- | --- | --- |
| GOP/s | Arithmetic throughput | Does not state completed images per second |
| FPS | Completed frames per second | Does not by itself state single-image latency |
| GOP/s/W | Arithmetic work per joule | Not the same as FPS/W |
| FPS/W | Completed frames per joule | Inherits the power measurement boundary |
| Training accuracy | A training-process measure | Not test accuracy or mAP |
| IoU | Bounding-box intersection area divided by union area | Not classification accuracy or mAP |
<!-- markdownlint-enable MD013 -->

For completion interval `T_interval`, `FPS = 1 / T_interval`. In a pipeline,
latency can exceed the completion interval. A robot therefore needs a defined
capture-to-result or capture-to-control boundary, not frame rate alone.

## Three studies, three levels of analysis

<!-- markdownlint-disable MD013 -->
| Study | Contribution to the seminar | Boundary |
| --- | --- | --- |
| Wan et al. [1] | Robotic workload map: sensing, perception, localisation, planning, control | A survey of different systems, not one common benchmark |
| Li et al. [2] | Memory-aware CNN dataflow and accelerator architecture | AlexNet and VGG-16 on a VC709 |
| Al Amin et al. [3] | Model preparation through edge deployment | YOLOv3-Tiny traffic-light detection on a KV260 |
<!-- markdownlint-enable MD013 -->

The progression is from isolated image kernels to CNN acceleration and
heterogeneous FPGA-plus-processor systems. The survey places FPGA kernels within
a larger robot, including sensor synchronisation and processor/GPU workloads.

Examples quoted in the seminar from Wan et al.'s survey include dense stereo at
507.9 FPS and 3.35 W, sparse ORB-SLAM at 31 FPS and 1.9 W, and a PerceptIn ORB
example reporting 83% energy savings at 44 FPS. These refer to different
workloads and boundaries. They show a design space, not a performance ranking.

## Li et al.: memory-aware CNN acceleration

### Kernel partition and data reuse

Li et al. address repeated memory access by partitioning an `M x N` convolution
kernel into `1 x 1` sub-kernels. Feature-map data are broadcast across
sub-kernels, and aligned partial maps are accumulated to form the output. For
stride `S`, channel stacking transforms the work into a stride-one form.

The studied architecture stages weights, biases, and feature maps near the PE
array. Kernel and feature-map registers reduce refetching. Row accumulation and
partial-sum addition assemble the output, with output feature maps stored in
BRAM.

```text
External memory -> Memory control -> Weight / bias / feature registers
                                    -> PE array
                                    -> Row accumulation / partial sums
                                    -> Output feature-map BRAM
```

### Platform and resources reported in the study

- Virtex-7 VC709 at 200 MHz.
- 664 instantiated PEs: 600 for convolution and 64 for fully connected layers.
- Reported utilisation: 28.0% LUT, 18.4% DSP, 31.7% BRAM.
- 16-bit feature maps and 8-bit weights.
- Reported power: 9.61 W.

### Published results

<!-- markdownlint-disable MD013 -->
| Network | Rate | Arithmetic throughput | Arithmetic efficiency |
| --- | --- | --- | --- |
| AlexNet | 151.4 FPS | 220.0 GOP/s | 22.9 GOP/s/W |
| VGG-16 | 7.28 FPS | 230.1 GOP/s | 23.9 GOP/s/W |
<!-- markdownlint-enable MD013 -->

Similar arithmetic rates do not imply similar frame rates. VGG-16 requires much
more work per image and spills feature maps to external memory. The AlexNet
first layer, with an `11 x 11` kernel and stride four, uses 363 of the 600
convolution PEs, or about 60.5% by direct division. The supplied deck labels
this 60.2%; the count and percentage should not be treated as an exact match.

### Timing caveat identified in the seminar

The deck compares the source's stage times with its reported rate:

```text
Convolution:       6.279 ms
Fully connected:   4.580 ms
Max pooling:       0.325 ms
Sequential sum:   11.184 ms -> about 89.4 FPS

1000 / 151.4 = about 6.605 ms
6.279 + 0.325 = 6.604 ms
```

The stage times and 151.4 FPS are not fully reconciled in the seminar's source
evidence. The reported rate must not be relabelled as single-image latency. The
deck also quotes convolution-only performance of 212.2 GOP/s and 159.2 FPS, with
a peak-layer arithmetic rate of 240.5 GOP/s.

## Al Amin et al.: YOLO deployment on the Kria KV260

### Task and model

The case study detects traffic lights using YOLOv3-Tiny, a `416 x 416` input,
eight classes, and two detection scales. The deck describes 5,094 Bosch dataset
images, with 1,019 forming the test set, and approximately 50,200 Darknet
training iterations. The eight classes distinguish traffic-light colour and
direction, including a no-light class.

### Published deployment chain

```text
Dataset preparation
  -> Darknet training
  -> TensorFlow conversion and frozen graph
  -> INT8 quantisation using 250 calibration images
  -> XIR / DPUCZDX8G compilation
  -> .xmodel on the Kria KV260
  -> DPU inference + software post-processing
```

The DPU runs in programmable logic; the CPU manages the rest of the application.
The seminar discusses the Linux/Kria PYNQ environment and notebook-based
execution in the published flow. Reproduction would need the tool versions,
model hashes, DPU fingerprint, calibration set, and preprocessing details.

### Published results and limits

<!-- markdownlint-disable MD013 -->
| Quantity | Reported value | Interpretation |
| --- | --- | --- |
| Completion rate | 15 FPS; 30 images in 1.996 s | Does not establish worst-case camera-to-control latency |
| Power | 3.5 W | Measurement boundary is not fully stated in the seminar's evidence |
| Training-curve value | 99% | Not mAP or test-set detection accuracy |
| Average IoU | 36% | A box-overlap measure, with an incomplete evaluation protocol |
<!-- markdownlint-enable MD013 -->

The deck notes that the 250 calibration images were drawn from the test set.
That matters when interpreting evaluation independence. Detection examples do
not replace a documented test protocol.

An earlier same-board result is quoted second-hand in Al Amin et al.: 8 W and
1.87 FPS/W versus 3.5 W and about 4.2 FPS/W. This is treated as a comparison
reported by that paper, not an independently reproduced benchmark.

## Comparative analysis

The seminar derives the following values. They are calculations from published
inputs, not new measurements:

<!-- markdownlint-disable MD013 -->
| Quantity | Calculation | Approximate result |
| --- | --- | --- |
| AlexNet implied power | `220.0 / 22.9` | 9.61 W |
| VGG-16 implied power | `230.1 / 23.9` | 9.63 W |
| AlexNet frame efficiency | `151.4 / 9.61` | 15.8 FPS/W |
| VGG-16 frame efficiency | `7.28 / 9.63` | 0.76 FPS/W |
| YOLOv3-Tiny frame efficiency | `15 / 3.5` | 4.29 FPS/W |
| AlexNet work per image | `220.0 / 151.4` | 1.45 GOP/image |
| VGG-16 work per image | `230.1 / 7.28` | 31.6 GOP/image |
<!-- markdownlint-enable MD013 -->

The work-per-image ratio is about 22. If the sequential 89.4 FPS interpretation
were used for AlexNet, its efficiency would instead be about 9.3 FPS/W. This
illustrates why timing interpretation matters.

These values do not rank the platforms. Networks, datasets, precision, task,
memory behaviour, and power boundaries differ. A lower power figure alone does
not establish lower energy per useful robot decision.

## Proposed robot architecture

The seminar synthesises the following architecture from the reviewed studies. It
was not implemented or measured:

```text
Camera -> FPGA timestamps / preprocessing -> Quantised YOLO accelerator
       -> Arm software: decode, NMS, object messages -> Object tracker

IMU + GNSS -> Visual-inertial localisation -> Pose estimate

Tracked objects + pose -> Planner / decision logic -> Actuator commands
Radar + sonar -> Independent safety controller -> Safety override
```

### Timing at 15 FPS

A 15 FPS detector completes a frame about every 66.7 ms. A 60 FPS source
supplies one every 16.7 ms. Under that illustrative source-rate assumption, the
detector handles roughly one frame in four, rather than every captured frame.

The design discussion favours the newest frame, hardware timestamps, sensor
synchronisation, and tracking between detections. This is a proposed integration
policy, not proof of a safe control deadline. Capture, preprocessing, transfer,
inference, decoding, queueing, planning, and actuation all contribute to result
age.

### Energy, thermal behaviour, and safety

The complete robot needs a power budget covering sensors, compute, memory,
interfaces, and control. The seminar argues for energy per completed useful
decision, rather than detector power alone. Measurements should account for
thermal equilibrium. Frequency/voltage changes are only useful if deadlines
remain satisfied.

Reliability considerations include watchdogs, monitoring, safe states,
independent safety sensing, and the resource cost of redundancy. Reconfiguration
needs bounded switching time and a demonstrated benefit.

## Design guidelines and evidence limits

- Put regular streaming kernels in FPGA logic and keep coordination in processor
  software.
- Improve reuse before increasing the PE count.
- Calibrate reduced precision and retain adequate accumulator width.
- Report FPS, latency, power, FPS/W, and detection metrics separately.
- Specify dataset splits, class-wise quality, thresholds, and calibration data.
- Timestamp frames and account for stale or missed results.
- Pin tools, model hashes, DPU configuration, preprocessing, and power
  procedure.
- Evaluate reliability and safe-state behaviour at the system boundary.

The review covers three primary papers with different systems and metrics.
Nothing was reproduced independently. The Li timing discrepancy remains
unresolved, and Al Amin's training value is not test accuracy. Derived
efficiencies inherit the input power boundaries. The proposed robot is a
synthesis, not a prototype.

## Research gaps and future scope

The central gap is a common end-to-end evaluation of the camera-to-action chain
under one measurement boundary. The seminar identifies:

1. Comparable datasets, latency definitions, and power procedures.
2. Capture-to-control timing beyond inference alone.
3. Detection-quality reporting using mAP at stated IoU thresholds and class-wise
   results.
4. Direct memory-traffic and energy measurements.
5. Real-time guarantees for partial reconfiguration.
6. Long-duration reliability and safety evaluation.
7. Toolchain portability across vendors.
8. Reproducible splits, calibration, model versions, and power measurements.

Possible directions include layer-adaptive precision and dataflow, bounded
runtime reconfiguration, sensor fusion inside the fabric, hardware-error
analysis tied to task risk, and standard edge-robotics benchmarks. These are
directions identified by the review, not work completed or a promise of future
implementation.

## Sources and repository contents

The primary source for this repository write-up is my supplied 40-slide seminar
deck, the verified seminar presentation. The write-up follows its findings while
distinguishing source-reported values, seminar-derived calculations, and
proposed design.

<!-- markdownlint-disable MD013 -->
| Path | Contents |
| --- | --- |
| [docs/Seminar_Report.md](docs/Seminar_Report.md) | Study map and slide-to-topic provenance |
| [papers/references.md](papers/references.md) | Principal paper citations and supporting reading |
| [references/README.md](references/README.md) | Platforms, dataset, and tool-flow context |
| `verilog/`, `vhdl/`, `examples/` | Existing scaffold directories; no implementation or examples are claimed |
| `images/` | Figure provenance note; no extracted third-party figures |
<!-- markdownlint-enable MD013 -->

### Principal references

[1] Z. Wan et al., "A survey of FPGA-based robotic computing," *IEEE Circuits
and Systems Magazine*, vol. 21, no. 2, pp. 48-74, 2021. DOI:
`10.1109/MCAS.2021.3071609`.

[2] J. Li, K.-F. Un, W.-H. Yu, P.-I. Mak, and R. P. Martins, "An FPGA-based
energy-efficient reconfigurable convolutional neural network accelerator for
object recognition applications," *IEEE Transactions on Circuits and Systems II:
Express Briefs*, vol. 68, no. 9, pp. 3143-3147, 2021. DOI:
`10.1109/TCSII.2021.3095283`.

[3] R. Al Amin, M. Hasan, V. Wiese, and R. Obermaisser, "FPGA-based real-time
object detection and classification system using YOLO for edge computing," *IEEE
Access*, vol. 12, pp. 73268-73278, 2024. DOI: `10.1109/ACCESS.2024.3404623`.

Published measurements and third-party material remain attributed to their
original authors. The repository's existing `LICENSE` file is unchanged.
