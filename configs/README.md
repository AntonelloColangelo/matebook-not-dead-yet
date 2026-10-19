# Configuration inventory

The four `.diff` files compare selected relevant symbols with Mint `7.0.0-38-generic`. They are readable inventory differences, not patches to apply to a full `.config`. `absent` means the symbol was not present in that file; it is distinct from explicitly disabled (`n`). Differences may reflect the kernel-version change.

The selection covers scheduling, preemption, tick frequency, RCU, compiler/LTO, CPU targeting, NUMA, unwinding, memory compression and relevant debugging. Driver-by-driver pruning and unrelated version-specific symbols are omitted. Private signing-key paths are never copied.

`config-sha256.txt` contains hashes of the original complete build configurations. During the repository inventory, efficiency, thinlto and reactive configurations matched their installed copies; reactive2 matched the live configuration from `/proc/config.gz`. The hashes refer to the original files, not these selected diffs. They do not prove binary identity.

`boot-parameters.tsv` distinguishes configured entries from the live observation. The generated Mint boot entry and its GRUB ID remain unverified because the protected GRUB file could not be read. The other IDs were read from `custom.cfg`. Identifying boot paths and disk parameters are omitted.

`sysctl.txt` records shared memory tuning and crash settings observed during the repository inventory. These are not per-kernel changes.
