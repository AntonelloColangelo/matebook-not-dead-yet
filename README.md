# Can kernel tuning improve an ageing laptop? An AI-assisted case study

## Abstract

This project explores whether tuning the Linux kernel can help me keep using an ageing Huawei MateBook 14 instead of buying a replacement. I also use it to access the computer that runs my genome analyses remotely. AI agents helped prepare custom kernels and benchmark scripts under my direction. I plan to compare these kernels with the installed Mint kernel by measuring how long Firefox, Claude and Codex take to show a window under CPU load, and how much power the laptop uses at idle. The benchmarks have not been run and remain paused. No results are available yet, so I cannot say whether the custom kernels offer an improvement.

## Introduction

I'm a junior bioinformatician, and I want to keep using my Huawei MateBook 14 with a Ryzen 5 2500U and 8 GB of RAM. My main reason for this project is practical: I want to postpone buying a replacement while keeping everyday applications usable. I also use this laptop to connect remotely to the computer where I run my genome analyses, documented in my [whole-genome sequencing project](https://github.com/AntonelloColangelo/gpu-wgs-variant-calling). The analyses run on that other computer, so keeping this laptop responsive would help me continue using it for remote work.

Moving from Windows 10 to Linux Mint already made the laptop much more comfortable for me to use. This is my experience, rather than a measured comparison between the two systems. After the changes I had already tried, the kernel seemed like one of the few remaining parts of the system where I could look for further improvements. It manages CPU time and memory, so I thought tuning it for my hardware was worth testing. I used AI agents to help prepare the custom kernels and document the changes. Any benefit still needs to be measured.

I chose Firefox, Claude and Codex for the tests because they are among the applications I use most often. The experiment asks whether the custom kernels make these applications open faster without increasing idle power use.

Viduka and colleagues studied the reuse of old computers with open source software [1]. Their work provides background for trying software changes before replacing hardware. It uses older Windows and Ubuntu versions, so it does not tell us how this laptop or today's applications will perform. It also does not evaluate AI assistance.

**Benchmarks are paused.** There are no measurements for this protocol yet. The planned tests compare Linux kernels on the same laptop. They do not compare Windows with Linux or measure how many extra years the laptop will remain useful.

## Methods

### Hardware

| Component | Setup |
|---|---|
| Laptop | Huawei MateBook 14, KPL-W0X |
| CPU | AMD Ryzen 5 2500U, 4 cores / 8 threads |
| RAM | 8 GB installed; approximately 6.7 GiB usable |
| Operating system | Linux Mint 22.3, X11 session required by the protocol |
| Battery | Worn; the recorded full-charge capacity was 80.3% of its original design capacity |
| Power readout | Battery current × voltage; the script also supports `power_now` |
| Reference kernel | Installed Mint kernel `7.0.0-38-generic`, with the laptop's existing settings |

The capacity ratio above comes from the hardware inventory. It does not measure battery runtime or the effect of a kernel change.

### What changed and why

| Kernel | Main changes | Added patches |
|---|---|---|
| Mint 7.0.0-38 | Reference kernel, with full preemption set in the boot configuration | Mint's own patches have not been reviewed here |
| 7.2.9-kpl-efficiency | Lazy preemption and build settings for this CPU | None listed in the build records |
| 7.2.9-kpl-thinlto | BORE scheduling, ThinLTO build optimization and full preemption at boot | BORE 6.8.0 |
| 7.2.9-kpl-reactive | Builds on thinlto, with changes to timing and background kernel work | BORE 6.8.0 |
| 7.2.9-kpl-reactive2 | Builds on reactive, with less debugging and changes to memory handling | BORE 6.8.0 and TTM beneficial_order |

BORE changes CPU scheduling to favour short bursts of work. The aim is to improve interactive response when tasks compete for CPU time. Whether that makes applications start faster on this laptop remains to be measured.

Preemption lets the kernel interrupt some of its current work so another task can run. Full and lazy preemption handle this differently, which may affect response time and CPU work. ThinLTO is a build option that optimizes code across different parts of the kernel.

`rcu_nocbs=all` moves a type of deferred kernel work, called RCU callbacks, to dedicated background threads. The lazy RCU setting allows some of this work to be grouped and delayed. I still need to measure whether this reduces power use here.

The custom kernels also include fewer drivers and build settings chosen for this CPU. Some features were already present in Mint. The memory settings apply to every kernel, including Mint, so they are not an advantage unique to the custom builds. The detailed settings are recorded in the files linked below.

The [configuration differences](configs/README.md), [build notes](docs/build-inventory.md) and [patch references](patches/README.md) record these changes. The experiment compares complete kernel configurations, so it cannot isolate the effect of an individual patch.

### What I will measure

I plan one session per kernel after reboot, with two measurements:

1. Time 10 launches each of Firefox, Claude desktop and Codex desktop while a fixed background task keeps all eight CPU threads busy. The script uses hyperfine for timing and stress-ng for the background work. Before each launch, it restores the same separate profile for each app and clears cached files from memory. Timing stops when the first app window appears. Preparing the profile and closing the app are not included.
2. Record battery power every five seconds for ten minutes, giving 120 readings while the laptop is idle. This happens before the CPU load, after a short settling period. The charger stays disconnected, brightness stays fixed, Wi-Fi stays on, and only the terminal remains open.

For Claude and Codex, a visible login or startup window also counts. This does not measure when the chat is ready or a response arrives. The test uses separate profiles without signing in. Profile isolation and window detection still need live checks. On this installation, Codex desktop launches with `chatgpt`, and Claude with `claude-desktop`. Clearing the operating-system cache does not guarantee that the drive's internal cache is empty. Idle power also does not tell us how long the battery will last during daily work.

### Running the scripts later

**The tests are still paused. Run these commands only when the measurements resume.** No script changes GRUB or reboots the computer. Each future reboot requires separate confirmation.

The scripts need Firefox, Claude desktop, Codex desktop, hyperfine, stress-ng, xdotool, Python 3 and NetworkManager. The analysis uses Matplotlib to draw the figure. These tools have not been installed as part of this project. Use hyperfine 1.x, version 1.15 or later within that series; the script does not support version 2.x.

After resuming, from the repository root:

```bash
# Prepare the dedicated profile once; close its window normally.
bash scripts/00-profile.sh

# With Claude and Codex fully closed, prepare their separate profiles.
bash scripts/00-electron-profiles.sh

# Run once per kernel, after reboot and manual preparation.
bash scripts/01-benchmark.sh

# Generate the table and figure from completed measurement CSVs.
python3 scripts/02-analyze.py
```

The Bash scripts have Italian comments and a linear layout. [Phase 2 instructions](FASE2.txt) describe conditions, cleanup and output fields; [phase 3 instructions](FASE3.txt) describe analysis and validation. Never run the whole benchmark as root; sudo is used only for cache clearing.

## Results

There are no measurement CSVs, numerical results or generated figures yet. This repository does not include earlier measurements made with other protocols.

Once measurements are available, the analysis script will produce one table in `docs/results-summary.md` and one scatter plot in `docs/figures/kernel-tradeoff.png`. The table reports median startup time in seconds, mean idle power in watts and percentage changes relative to Mint. The table has a row for each kernel and app, comparing startup times with the same app on Mint. The single figure has three panels, one per app, with startup time on x and idle power on y. Each panel has one point per measured kernel. The idle-power value is shared across the three panels; it is not the power consumed by each app. There is no combined startup score.

The script marks missing kernels as *Not measured* and leaves percentage changes unavailable if Mint has not been measured. It does not fill gaps with zeros or estimates. I will add the generated table and figure here after reviewing the measurements. The figure will always be regenerated from the CSVs, without manual changes to the points.

## Discussion

The practical question is whether these changes make this laptop comfortable enough for me to keep using. Faster application startup would help with one part of that experience. The tests do not cover every daily task, and idle power does not measure battery runtime during work.

AI agents helped write scripts and reconstruct the kernel configurations under my direction. That made it possible for me to work through changes that would be difficult to prepare alone. It does not establish that every change is correct or useful. The scripts have been reviewed and checked for syntax, but profile isolation, window detection and cleanup still need checks during actual runs. This project does not compare work done with and without AI.

The experiment compares complete kernel builds. If one performs better, I will not be able to attribute that difference to a single patch or setting. Small or null differences would also be useful: they would help me decide whether maintaining a custom kernel is worth the effort.

### Stated limitations

- This is one laptop with a worn battery. Other computers may give different results.
- I plan one session per kernel and 10 launches per app. This will not show how much the results change between reboots. The battery readings all come from the same session, not separate tests.
- Heat, CPU speed, background programs, Wi-Fi and screen settings can affect the results. Waiting before a test does not guarantee that the laptop has cooled down.
- The apps always run in the same order: Firefox, Claude, then Codex. Each gets the same CPU load and a ten-second wait before timing starts, but the laptop may be warmer for the later apps. Compare each app with itself across kernels.
- Several things change together, including the kernel version, build tools and settings. A better result would not tell us which change caused it.
- Mint already has changed memory and preemption settings. It is not a default installation.
- Timing stops when a window appears, not when the app is fully ready. Window detection and proper app shutdown still need to be checked in real runs.
- Power readings come from the laptop's battery sensor, not an external meter. The sensor has limited precision and refresh speed, and current and voltage are read one after the other.
- The analysis summarizes the measurements. It does not test whether small differences are meaningful or calculate a range of uncertainty. Idle power does not tell us how long the battery will last during everyday use.

## Conclusion

There is no measured basis yet for choosing a kernel. The next step, when benchmarks resume, is to collect startup times and idle power readings under the same conditions. A kernel that improves both would be a useful candidate for this laptop. If the results are mixed or show little difference, I will report that without claiming an improvement.

The aim remains to keep using the computer I already own. Whether a custom kernel helps enough to justify maintaining it is still an open question.

## AI-assisted implementation and ownership

AI agents wrote the scripts and helped reconstruct and document the configurations under my direction. The research question, protocol and practical choices are mine. I am responsible for taking and checking the measurements and interpreting the results. I have not taken those measurements yet. Reviewing the code is only a first step. I still need to check it during actual runs.

## Reference

[1] Viduka, D., Kraguljac, V., & Đurašković, J. (2021). *Analysis of the Use Value of Old Hardware Using Open Source Software*. Zbornik Veleučilišta u Rijeci, 9(1), 315–328. [Article and PDF](https://hrcak.srce.hr/257663). DOI: [10.31784/zvr.9.1.19](https://doi.org/10.31784/zvr.9.1.19).

## Where to find things

| Folder or file | What's inside |
|---|---|
| `scripts/` | Scripts to run the tests and read the results |
| `results/` | Test data, once collected |
| `configs/` | Kernel settings |
| `patches/` | References for the kernel changes |
| `docs/` | Build notes and, once data are available, the table and figure |
| `FASE2.txt` | Step-by-step testing instructions in Italian |
| `FASE3.txt` | How to read the results, in Italian |

Kernel images, initramfs files, source trees, private keys, browser profiles and build archives are excluded. Files are checked for personal paths, host identifiers and disk UUIDs before publication.
