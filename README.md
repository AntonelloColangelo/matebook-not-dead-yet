# Linux kernel responsiveness and idle power on a Huawei MateBook 14

Which kernel makes applications open faster while keeping idle power use low on a Ryzen 5 2500U laptop with 6.7 GiB of usable RAM?

I'm a junior bioinformatician, and this is an independent experiment on my laptop. I want to find out whether a custom kernel can make applications open faster without increasing energy use. I will compare the kernels under the same workload and keep the measurements alongside the scripts.

**Benchmarks are paused.** The scripts have been checked for syntax and reviewed, but have not been run on this hardware. There are no results for this protocol yet, so I cannot say whether any kernel is faster or uses less power.

## Hardware

| Component | Setup |
|---|---|
| Laptop | Huawei MateBook 14, KPL-W0X |
| CPU | AMD Ryzen 5 2500U, 4 cores / 8 threads |
| Usable RAM | Approximately 6.7 GiB |
| Operating system | Linux Mint 22.3, X11 session required by the protocol |
| Battery | Worn; the recorded full-charge capacity was 80.3% of its original design capacity |
| Power readout | Battery current × voltage; the script also supports `power_now` |
| Reference kernel | Installed Mint kernel `7.0.0-38-generic`, with the laptop's existing settings |

The capacity ratio above comes from the hardware inventory. It does not measure battery runtime or the effect of a kernel change.

## What changed and why

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

## What I will measure

I plan one session per kernel after reboot, with two measurements:

1. Time 10 Firefox launches while a fixed background task keeps all eight CPU threads busy. The script uses hyperfine for timing and stress-ng for the background work. Before each launch, it restores the same separate Firefox profile and clears cached files from memory. Timing stops when the Firefox window appears. Preparing the profile and closing Firefox are not included.
2. Record battery power every five seconds for ten minutes, giving 120 readings while the laptop is idle. This happens before the CPU load, after a short settling period. The charger stays disconnected, brightness stays fixed, Wi-Fi stays on, and only the terminal remains open.

A visible Firefox window does not necessarily mean the page has finished drawing or the browser is ready to use. Clearing the operating-system cache does not guarantee that the drive's internal cache is empty. Idle power also does not tell us how long the battery will last during daily work.

## Running the scripts later

**The tests are still paused. Run these commands only when the measurements resume.** No script changes GRUB or reboots the computer. Each future reboot requires separate confirmation.

The scripts need Firefox, hyperfine, stress-ng, xdotool, Python 3 and NetworkManager. The analysis uses Matplotlib to draw the figure. These tools have not been installed as part of this project. Use hyperfine 1.x, version 1.15 or later within that series; the script does not support version 2.x.

After resuming, from the repository root:

```bash
# Prepare the dedicated profile once; close its window normally.
bash scripts/00-profile.sh

# Run once per kernel, after reboot and manual preparation.
bash scripts/01-benchmark.sh

# Generate the table and figure from completed measurement CSVs.
python3 scripts/02-analyze.py
```

The Bash scripts have Italian comments and a linear layout. [Phase 2 instructions](FASE2.txt) describe conditions, cleanup and output fields; [phase 3 instructions](FASE3.txt) describe analysis and validation. Never run the whole benchmark as root; sudo is used only for cache clearing.

## Results

There are no measurement CSVs, numerical results or generated figures yet. This repository does not include earlier measurements made with other protocols.

Once measurements are available, the analysis script will produce one table in `docs/results-summary.md` and one scatter plot in `docs/figures/kernel-tradeoff.png`. The table reports median startup time in seconds, mean idle power in watts and percentage changes relative to Mint. The plot has startup time on the x-axis and power on the y-axis, with one point per measured kernel.

The script marks missing kernels as *Not measured* and leaves percentage changes unavailable if Mint has not been measured. It does not fill gaps with zeros or estimates. I will add the generated table and figure here after reviewing the measurements. The figure will always be regenerated from the CSVs, without manual changes to the points.

## Conclusion

I cannot choose a kernel from this protocol until there are measurements. A point lower and further left would be better on both measures. If a kernel starts Firefox faster but uses more power, the choice will depend on which matters more. I will report small or null differences as they are. The configuration changes alone do not show an improvement.

## Stated limitations

- The results will apply to this laptop and its worn battery. One planned session per kernel gives little basis for generalizing to other machines.
- Ten startup repetitions are few. Consecutive battery readings are not independent sessions, and between-reboot variability is not measured.
- Temperature, CPU frequency, background services, Wi-Fi activity and display configuration can affect both measurements. A settling delay does not prove that temperature has stabilized.
- The comparison changes the kernel version from 7.0 to 7.2.9, compiler, configuration and patches together. It cannot attribute a difference to BORE, ThinLTO or RCU alone.
- Mint uses the laptop's existing memory settings and a changed preemption setting. It is not an untouched default installation.
- The startup measurement stops when the window appears. I still need to check that the script detects the correct Firefox window and closes its processes properly.
- Battery sensors have finite resolution and update intervals; current and voltage are read consecutively. No external wattmeter is used.
- The analysis reports descriptive statistics, with no significance test or uncertainty interval. It does not establish battery runtime under real workloads.

## AI-assisted implementation and ownership

AI agents wrote the scripts and helped reconstruct and document the configurations under my direction. The research question, protocol and practical choices are mine. I am responsible for taking and checking the measurements and interpreting the results. I have not taken those measurements yet. Reviewing the code is only a first step. I still need to check it during actual runs.

## Repository map

| Path | Purpose |
|---|---|
| `configs/` | Selected config differences, hashes, sanitized boot parameters and global tuning |
| `patches/` | Patch references and hashes only; no kernel source code |
| `scripts/` | Measurement preparation, benchmark and analysis |
| `results/` | Reserved for completed per-kernel measurement CSVs |
| `docs/figures/` | Reserved for the figure generated from real data |
| `docs/build-inventory.md` | Reconstruction of the retained build evidence |

Kernel images, initramfs files, source trees, private keys, browser profiles and build archives are excluded. Files are checked for personal paths, host identifiers and disk UUIDs before publication.
