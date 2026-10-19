# Linux kernel tuning on an ageing laptop: an AI-assisted case study

## Project overview

This project explores whether tuning the Linux kernel can help me keep using an ageing Huawei MateBook 14 instead of buying a replacement. I also use it to connect remotely to the computer that runs my genome analyses. AI agents helped prepare custom kernels and document their configurations under my direction. This repository contains configuration differences, build notes and patch references. It also records my perception of less stuttering and better responsiveness with reactive2 than with the Mint kernel. These observations are anecdotal.

## Why I worked on this

I'm a junior bioinformatician, and I want to keep using my Huawei MateBook 14 with a Ryzen 5 2500U and 8 GB of RAM. My main reason for this project is practical: I want to postpone buying a replacement while keeping everyday applications usable. I also use this laptop to connect remotely to the computer where I run my genome analyses, documented in my [whole-genome sequencing project](https://github.com/AntonelloColangelo/gpu-wgs-variant-calling).

After moving from Windows 10 to Linux Mint, I explored kernel configurations for this hardware. I wanted to understand which scheduling, memory and build settings I could change.

Viduka and colleagues studied the reuse of old computers with open source software [1]. Their work provides background for trying software changes before replacing hardware. It uses older Windows and Ubuntu versions, so it does not tell us how this laptop or today's applications will perform.

This case study documents kernel changes on one laptop. It does not establish a measured advantage over Windows or show how many extra years the laptop will remain useful.

## Documented setup

### Hardware

These details come from the inventory used to prepare this repository. They describe that recorded setup, not a continuously updated system report.

| Component | Setup |
|---|---|
| Laptop | Huawei MateBook 14, KPL-W0X |
| CPU | AMD Ryzen 5 2500U, 4 cores / 8 threads |
| RAM | 8 GB installed; approximately 6.7 GiB usable |
| Operating system | Linux Mint 22.3 |
| Battery | Recorded full-charge capacity was 80.3% of its original design capacity |
| Installed Mint kernel | Mint `7.0.0-38-generic`, with the laptop's existing settings |

The battery figure describes its condition, not how long it lasts on a charge.

### Kernel configurations

The project documents four custom kernels based on Linux 7.2.9 alongside the installed Mint kernel:

| Kernel | Main changes |
|---|---|
| kpl-efficiency | Lazy preemption and build settings chosen for this CPU |
| kpl-thinlto | BORE 6.8.0, ThinLTO and full preemption configured at boot |
| kpl-reactive | Based on thinlto, with full preemption in the build configuration, HZ1000, ORC unwinding and RCU boot settings |
| kpl-reactive2 | Based on reactive, with ACPI debugging disabled, ZRAM_MULTI_COMP enabled and the TTM beneficial_order patch |

The table summarizes the recorded changes between custom builds. The `.diff` files instead compare each custom configuration with Mint. A setting inherited from an earlier custom build may therefore appear in several diffs.

Build settings and boot parameters describe different parts of the setup. For example, the recorded thinlto boot entry selects `preempt=full`, overriding the lazy-preemption default described in older build notes. Only reactive2 was running when the inventory was collected.

The recorded Mint boot defaults also select full preemption. The shared `sysctl` settings apply across kernels, while build options such as the default zram compressor differ. The [configuration inventory](configs/README.md), [build notes](docs/build-inventory.md) and [patch references](patches/README.md) explain these distinctions.

## Personal observations

In everyday use, the laptop feels more immediate and responsive with `7.2.9-kpl-reactive2` than with the original Linux Mint `7.0.0-38-generic` kernel. I notice less stuttering when using applications and when opening several programs. The difference is particularly noticeable when multiple applications are open at the same time.

These are anecdotal observations from my use of this laptop. They describe a perceived improvement, without quantifying it or establishing which kernel change caused it. The Mint kernel was the distribution-provided build, with the local system settings documented in this repository.

I have not established lower power consumption or longer battery life.

## Scope and limitations

This is a personal case study on one laptop. Kernel versions, compilers, patches and settings changed together, so the records do not establish the effect of an individual change. Mint also had local system settings and was not a default installation.

The technical files reconstruct earlier builds from retained scripts, configurations and manifests. They distinguish recorded settings from runtime observations. The selected configuration diffs and command summaries are not complete rebuild instructions, and the recorded source URLs have not been independently revalidated.

## AI-assisted implementation and ownership

AI agents helped reconstruct and document the configurations under my direction. The project question and practical choices are mine. I am responsible for checking the evidence and interpreting the observations. AI assistance does not establish that every change is correct or useful.

## Reference

[1] Viduka, D., Kraguljac, V., & Đurašković, J. (2021). *Analysis of the Use Value of Old Hardware Using Open Source Software*. Zbornik Veleučilišta u Rijeci, 9(1), 315–328. [Article and PDF](https://hrcak.srce.hr/257663). DOI: [10.31784/zvr.9.1.19](https://doi.org/10.31784/zvr.9.1.19).

## Where to find things

| Folder or file | What's inside |
|---|---|
| `configs/` | Kernel settings |
| `patches/` | References for the kernel changes |
| `docs/` | Build notes |

Kernel images, initramfs files, source trees, private keys and build archives are excluded. The published inventory omits personal paths, host identifiers and disk UUIDs.
