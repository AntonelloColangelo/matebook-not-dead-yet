# Linux kernel responsiveness and idle power on a Huawei MateBook 14

Which kernel offers the best trade-off between application startup time and idle battery power on a Ryzen 5 2500U laptop with 6.7 GiB of usable RAM?

I'm a junior bioinformatician, and this is an independent experiment on my laptop. I want to find out whether a custom kernel can make applications open faster without increasing energy use. I will compare the kernels under the same workload and keep the measurements alongside the scripts.

**Benchmarks are paused.** The measurement and analysis scripts have had static checks, but have not been run on this hardware. There are no results for this protocol yet, so I cannot say whether any kernel is faster or uses less power.

## Hardware

| Component | Setup |
|---|---|
| Laptop | Huawei MateBook 14, KPL-W0X |
| CPU | AMD Ryzen 5 2500U, 4 cores / 8 threads |
| Usable RAM | Approximately 6.7 GiB |
| Operating system | Linux Mint 22.3, X11 session required by the protocol |
| Battery | Worn; full-charge capacity was 80.3% of design capacity at the inventory snapshot |
| Power readout | Battery current × voltage; the script also supports `power_now` |
| Baseline | Installed Mint kernel `7.0.0-38-generic`, with existing shared system tuning |

The capacity ratio above comes from the hardware inventory. It does not measure battery runtime or the effect of a kernel change.

## What changed and why

| Kernel | Main configuration | Documented source patches |
|---|---|---|
| Mint 7.0.0-38 | GCC 13.3, HZ=1000; `preempt=full` configured in GRUB defaults | Distribution patch set not reconstructed |
| 7.2.9-kpl-efficiency | GCC 13.3, HZ=250, lazy preemption, native CPU targeting | No external patch declared in the retained manifest |
| 7.2.9-kpl-thinlto | Clang/LLD 19.1.1, ThinLTO, BORE, HZ=250; boot override `preempt=full` | BORE 6.8.0 |
| 7.2.9-kpl-reactive | Clang/LLD 19.1.1, ThinLTO, BORE, HZ=1000, full preemption, RCU offloading | BORE 6.8.0 |
| 7.2.9-kpl-reactive2 | reactive configuration plus disabled ACPI debugging and enabled zram multiple compression support | BORE 6.8.0 and TTM beneficial_order |

BORE changes CPU scheduling to favour short bursts of work. The aim is to improve interactive response when tasks compete for CPU time. Whether that makes applications start faster on this laptop remains to be measured.

Preemption controls when running kernel work can yield to other runnable tasks. Full and lazy preemption trade latency against overhead, and their effect here still needs measurement. ThinLTO optimizes code across compilation units.

`rcu_nocbs=all` moves RCU callback processing to dedicated kernel threads. Together with `rcutree.enable_rcu_lazy=1`, it changes how callbacks are scheduled and batched. Lower power consumption is not guaranteed.

All custom kernels also use a reduced driver configuration, native CPU targeting, disabled NUMA and idle tick suppression. MGLRU and the underlying RCU capabilities already exist in the Mint baseline. Memory sysctls apply globally, including when Mint is booted. The active zram compressor at inventory time was ZSTD, although the custom kernel configuration defaults to LZ4.

The [configuration differences](configs/README.md), [build notes](docs/build-inventory.md) and [patch references](patches/README.md) record these changes. The experiment compares complete kernel configurations, so it cannot isolate the effect of an individual patch.

## Measurement protocol

I plan one session per kernel after reboot, with two measurements:

1. Measure 10 cold starts of Firefox with hyperfine while `stress-ng --cpu 8 --cpu-method int64` runs. Before each repetition, the script copies the same initialized Firefox profile and clears the operating-system caches. Timing ends when xdotool detects that process's visible Firefox window on X11. Copying the profile and closing Firefox are outside the timed interval.
2. Record 120 battery-power readings at five-second deadlines over ten minutes of idle time. This happens before the CPU load, after a short settling period. The charger stays disconnected, brightness stays fixed, Wi-Fi stays on, and only the terminal remains open.

Window visibility does not establish that Firefox has finished rendering or is ready for interaction. Clearing the operating-system cache does not guarantee that the drive's internal cache is empty. Idle power also does not tell us how long the battery will last during daily work.

## Scripts and future execution

**Do not run the measurement scripts until the benchmark campaign is explicitly resumed.** No script changes GRUB or reboots the computer. Each future reboot requires separate confirmation.

The scripts need Firefox, hyperfine 1.x starting with version 1.15, stress-ng, xdotool, Python 3, NetworkManager and standard Linux tools. The analysis also needs Matplotlib. These dependencies have not been installed as part of this project. The benchmark script rejects hyperfine 2.x because its JSON format differs.

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
- The installed Mint baseline includes global tuning and a configured preemption override. It is not a pristine Mint installation.
- The startup measurement ends at window visibility. Matching the window to the process ID and cleaning up the processes still need to be checked on this Firefox installation.
- Battery sensors have finite resolution and update intervals; current and voltage are read consecutively. No external wattmeter is used.
- The analysis reports descriptive statistics, with no significance test or uncertainty interval. It does not establish battery runtime under real workloads.

## AI-assisted implementation and ownership

AI agents wrote the scripts and helped reconstruct and document the configurations under my direction. The research question, protocol and practical choices are mine. I am responsible for taking and checking the measurements and interpreting the results. I have not taken those measurements yet. The code still needs to be validated through actual runs, regardless of its static checks.

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
