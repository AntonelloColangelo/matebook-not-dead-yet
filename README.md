# Linux kernel responsiveness and idle power on a Huawei MateBook 14

**Which kernel offers the best trade-off between application startup time and idle battery power on a Ryzen 5 2500U laptop with 6.7 GiB of usable RAM?**

This is an independent hardware experiment by a junior bioinformatician. The aim is to make an existing laptop more responsive without increasing its energy use. The approach is straightforward: state the question, keep the workload fixed, retain the measurements, and report what they do and do not establish.

**Status: benchmarks are paused. No results are available for this protocol.** The measurement and analysis scripts have been prepared and checked statically, but have not been run on this hardware. No speedup, power saving or winning kernel has been established.

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

The battery capacity ratio is an inventory observation, not a benchmark result or a battery-runtime estimate.

## What changed and why

| Kernel | Main configuration | Documented source patches |
|---|---|---|
| Mint 7.0.0-38 | GCC 13.3, HZ=1000; `preempt=full` configured in GRUB defaults | Distribution patch set not reconstructed |
| 7.2.9-kpl-efficiency | GCC 13.3, HZ=250, lazy preemption, native CPU targeting | No external patch declared in the retained manifest |
| 7.2.9-kpl-thinlto | Clang/LLD 19.1.1, ThinLTO, BORE, HZ=250; boot override `preempt=full` | BORE 6.8.0 |
| 7.2.9-kpl-reactive | Clang/LLD 19.1.1, ThinLTO, BORE, HZ=1000, full preemption, RCU offloading | BORE 6.8.0 |
| 7.2.9-kpl-reactive2 | reactive configuration plus disabled ACPI debugging and enabled zram multiple compression support | BORE 6.8.0 and TTM beneficial_order |

**BORE** changes CPU scheduling to favour short bursts of work, with the intention of improving interactive response under contention. It is a candidate mechanism, not evidence that applications start faster on this laptop.

**Preemption** controls when running kernel work can yield to other runnable tasks. Full and lazy preemption make different latency/overhead trade-offs; their effect here needs measurement. ThinLTO additionally optimizes across compilation units.

**`rcu_nocbs=all`** moves RCU callback processing to dedicated kernel threads. Together with `rcutree.enable_rcu_lazy=1`, it is intended to alter callback timing and batching; neither flag guarantees lower power consumption.

All custom kernels also use a reduced driver configuration, native CPU targeting, disabled NUMA and idle tick suppression. MGLRU and the underlying RCU capabilities already exist in the Mint baseline. Memory sysctls apply globally, including when Mint is booted. The active zram compressor at inventory time was ZSTD, although the custom kernel configuration defaults to LZ4.

See [selected configuration differences](configs/README.md), [build reconstruction](docs/build-inventory.md) and [patch provenance](patches/README.md). These are comparisons of complete kernel configurations, not isolated tests of individual patches.

## Measurement protocol

Only two outcomes are planned, once per kernel after reboot:

1. **Firefox cold startup:** 10 repetitions with hyperfine under `stress-ng --cpu 8 --cpu-method int64`. Each repetition copies the same initialized, dedicated Firefox profile and clears the operating-system caches. Timing ends when xdotool detects the launched process's visible Firefox window on X11. Profile preparation and process shutdown are outside the timing.
2. **Idle battery power:** 120 samples at five-second deadlines over ten minutes. This runs before the CPU load, after a short settling period, with the charger disconnected, fixed brightness, Wi-Fi on and only the terminal open.

The startup measure is time to a visible window, not full rendering or interactivity. Cold cache refers to the operating-system cache, not a guarantee about the drive's internal cache. The power measure is idle power, not battery runtime during daily work.

## Scripts and future execution

**Do not run the measurement scripts until the benchmark campaign is explicitly resumed.** No script changes GRUB or reboots the computer. Each future reboot requires separate confirmation.

The prerequisites are Firefox, hyperfine 1.15–1.x, stress-ng, xdotool, Python 3, NetworkManager and standard Linux tools. Analysis additionally needs Matplotlib. Dependencies have not been installed as part of this project. Hyperfine 2.x is deliberately rejected because its JSON format differs.

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

**Not yet available.** There are no measurement CSVs, numerical results or generated figures in this version. Historical measurements from other protocols have not been imported.

Once real CSVs exist, the analysis generates exactly one summary table (`docs/results-summary.md`) and one scatter plot (`docs/figures/kernel-tradeoff.png`). The table reports median startup seconds, mean idle watts and percentage changes relative to Mint. The plot places startup time on x and power on y, with one point per measured kernel.

Missing kernels are marked *Not measured*. Without Mint, percentage changes remain unavailable. No missing value is replaced with zero or an estimate. The figure is regenerated from data, never drawn or adjusted manually. The generated table and figure will be embedded here after measurement and review.

## Conclusion

There is currently no evidence from this protocol to choose a kernel. A point lower and further left would be preferable on both outcomes, but faster startup at higher power is a trade-off, not a unique winner. Small or null differences will be reported as such; configuration changes alone are not performance evidence.

## Stated limitations

- One laptop, one worn battery and one planned session per kernel limit generalization.
- Ten startup repetitions are few. Consecutive battery readings are not independent sessions, and between-reboot variability is not measured.
- Thermal state, CPU frequency, background services, Wi-Fi activity and display configuration can affect both outcomes. A settling delay does not prove thermal equilibrium.
- The comparison changes the kernel version from 7.0 to 7.2.9, compiler, configuration and patches together. It cannot attribute a difference to BORE, ThinLTO or RCU alone.
- The installed Mint baseline includes global tuning and a configured preemption override. It is not a pristine Mint installation.
- Window visibility is a limited startup endpoint. PID/window matching and process cleanup still need live validation on this Firefox installation.
- Battery sensors have finite resolution and update intervals; current and voltage are read consecutively. No external wattmeter is used.
- The analysis is descriptive, with no significance test or uncertainty interval. It does not establish autonomy under real workloads.

## AI-assisted implementation and ownership

AI agents implemented the scripts and helped reconstruct and document the configurations under my direction. I define the research question, protocol and practical choices, and I am responsible for conducting and reviewing the measurements and interpreting the results. The measurements have not yet been performed. AI-generated code and static checks do not substitute for experimental validation.

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
