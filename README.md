# Can kernel tuning improve an ageing laptop? An AI-assisted case study

## Abstract

This project explores whether tuning the Linux kernel can help me keep using an ageing Huawei MateBook 14 instead of buying a replacement. I also use it to connect remotely to the computer that runs my genome analyses. AI agents helped prepare custom kernels and document their configurations under my direction. The everyday usability observations reported here are anecdotal and do not establish a performance advantage from kernel tuning.

## Introduction

I'm a junior bioinformatician, and I want to keep using my Huawei MateBook 14 with a Ryzen 5 2500U and 8 GB of RAM. My main reason for this project is practical: I want to postpone buying a replacement while keeping everyday applications usable. I also use this laptop to connect remotely to the computer where I run my genome analyses, documented in my [whole-genome sequencing project](https://github.com/AntonelloColangelo/gpu-wgs-variant-calling).

Moving from Windows 10 to Linux Mint already made the laptop much more comfortable for me to use. This is my experience, rather than a measured comparison between the two systems. After the changes I had already tried, the kernel seemed like one of the few remaining parts of the system where I could look for further improvements. It manages CPU time and memory, so I explored configurations for my hardware.

Viduka and colleagues studied the reuse of old computers with open source software [1]. Their work provides background for trying software changes before replacing hardware. It uses older Windows and Ubuntu versions, so it does not tell us how this laptop or today's applications will perform. It also does not evaluate AI assistance.

This case study documents kernel changes on one laptop. It does not establish a measured advantage over Windows or show how many extra years the laptop will remain useful.

## Methods

### Hardware

| Component | Setup |
|---|---|
| Laptop | Huawei MateBook 14, KPL-W0X |
| CPU | AMD Ryzen 5 2500U, 4 cores / 8 threads |
| RAM | 8 GB installed; approximately 6.7 GiB usable |
| Operating system | Linux Mint 22.3 |
| Battery | Recorded full-charge capacity was 80.3% of its original design capacity |
| Reference kernel | Mint `7.0.0-38-generic`, with the laptop's existing settings |

The battery figure describes its condition, not how long it lasts on a charge.

### Kernel configurations

The project documents four custom kernels based on Linux 7.2.9 alongside the installed Mint kernel:

| Kernel | Main changes |
|---|---|
| kpl-efficiency | Lazy preemption and build settings chosen for this CPU |
| kpl-thinlto | BORE scheduling, ThinLTO build optimization and full preemption |
| kpl-reactive | Based on thinlto, with changes to timing and background kernel work |
| kpl-reactive2 | Based on reactive, with less debugging and changes to memory handling |

BORE gives priority to short bursts of CPU work. Preemption lets the kernel interrupt its work so another task can run. ThinLTO optimizes code when the kernel is built. The RCU settings change how some background kernel work is handled and delayed.

Mint already has changed preemption settings, and the same memory settings apply to every kernel. The [configuration differences](configs/README.md), [build notes](docs/build-inventory.md) and [patch references](patches/README.md) contain the exact options and patch versions.

## Results

The observations about everyday usability in this case study are **anecdotal**: they reflect my experience on one laptop, without a controlled comparison. They do not quantify a speedup, demonstrate longer battery life or isolate the effect of a particular kernel change.

## Discussion

AI assistance helped me prepare and document the kernel changes. It does not establish that every change is correct or useful. This project does not compare work done with and without AI.

A controlled comparison would be needed to decide whether maintaining a custom kernel offers a measurable benefit on this laptop.

### Stated limitations

- Personal impressions of usability are anecdotal and cannot substitute for controlled performance measurements.
- This is one laptop with a worn battery. Other computers may give different results.
- Heat, CPU speed, background programs, Wi-Fi and screen settings can affect performance and power use.
- Several things change together, including the kernel version, build tools and settings. A better result would not tell us which change caused it.
- Mint already has changed memory and preemption settings. It is not a default installation.

## Conclusion

This repository documents the kernel changes and my anecdotal experience of using the laptop. Performance gains, lower power use and longer battery life have not been demonstrated.

## AI-assisted implementation and ownership

AI agents helped reconstruct and document the configurations under my direction. The project question and practical choices are mine. I am responsible for checking the evidence and interpreting the observations.

## Reference

[1] Viduka, D., Kraguljac, V., & Đurašković, J. (2021). *Analysis of the Use Value of Old Hardware Using Open Source Software*. Zbornik Veleučilišta u Rijeci, 9(1), 315–328. [Article and PDF](https://hrcak.srce.hr/257663). DOI: [10.31784/zvr.9.1.19](https://doi.org/10.31784/zvr.9.1.19).

## Where to find things

| Folder or file | What's inside |
|---|---|
| `configs/` | Kernel settings |
| `patches/` | References for the kernel changes |
| `docs/` | Build notes |

Kernel images, initramfs files, source trees, private keys and build archives are excluded. Files are checked for personal paths, host identifiers and disk UUIDs before publication.
