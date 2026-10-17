# Patch provenance

`references.json` records the source URLs and hashes from retained build manifests. Patch SHA256 hashes were recalculated from local patch files during preparation. The source-archive hash is a recorded manifest value, not a new rehash of the archive. Remote availability and provenance have not been independently revalidated here.

| Kernel | Documented patches |
|---|---|
| efficiency | None declared |
| thinlto | BORE 6.8.0 |
| reactive | BORE 6.8.0; reused the thinlto source tree |
| reactive2 | BORE 6.8.0 plus TTM beneficial_order, v5 3/5 |

BORE's repository commit is pinned in the JSON. The TTM reference identifies the original patch submission. During phase 1, reverse dry-run checks confirmed the retained source trees contained the patches. This does not prove that every source file was unchanged or that an installed binary was built from that exact tree.

This directory intentionally contains references and hashes only, without patch code, kernel sources or signing material.
