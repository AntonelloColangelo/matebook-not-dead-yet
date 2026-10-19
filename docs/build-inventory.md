# Build reconstruction

This inventory comes from retained build scripts, configurations and manifests. It is a reconstruction of previous work, not a newly executed kernel build. Personal paths and build-user/host strings have been omitted.

| Kernel | Configuration origin | Toolchain | Recorded final build |
|---|---|---|---|
| efficiency | Mint 7.0.0-38 config, localmodconfig, explicit restoration of needed functionality | GCC 13.3.0; GNU ld 2.42 | `make -j5 bzImage modules`; initial pass used -j3 |
| thinlto | efficiency config plus BORE and ThinLTO | Clang/LLD 19.1.1 | `make -j4 bzImage`, then `make -j4 modules` |
| reactive | thinlto config, full preemption/HZ1000/ORC and CPU-support changes | Clang/LLD 19.1.1 | `make -j4 bzImage`, then `make -j4 modules` |
| reactive2 | reactive config plus ACPI-debug removal and ZRAM_MULTI_COMP | Clang/LLD 19.1.1 | `make -j4 bzImage`, then `make -j4 modules` |

These commands summarize the targets and parallelism; they are not standalone rebuild recipes. Original wrappers selected separate source and output trees and set toolchain/library paths. All custom builds selected `CONFIG_X86_NATIVE_CPU=y`; retained compiler evidence records native Zen1 targeting. LLVM builds used separate ThinLTO caches and linker wrappers with `flock`, `--threads=1` and `--thinlto-jobs=2`.

The source archive and patch references are in [patch provenance](../patches/references.json). Original configurations are identified by [SHA256](../configs/config-sha256.txt); only selected, sanitized differences are committed.

Historical reports record successful compilation, signed images/modules and VM checks. Those checks have not been repeated in this project and do not establish performance or battery-life benefits. No private keys, binaries, certificates or source trees are included.

Some original notes described thinlto with lazy preemption. The later `custom.cfg` entry overrides it with `preempt=full`; the boot-parameter inventory takes precedence over older prose. Only reactive2 was live during the repository inventory. The other entries describe configured settings rather than verified runtime states.

The configuration changes reflect the choices made for this laptop. Their performance benefits have not been established.
