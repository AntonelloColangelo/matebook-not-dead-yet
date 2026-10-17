#!/usr/bin/env bash
set -euo pipefail

## AVVIO FINO ALLA FINESTRA VISIBILE
cd -- "${BENCH_ROOT:?}/work/${BENCH_KERNEL:?}/firefox"
setsid firefox \
    --no-remote \
    --new-instance \
    --profile "$PWD/profile" \
    about:blank \
    > firefox.log 2>&1 &
echo "$!" > firefox.pid

# Il PID limita la ricerca alla nostra istanza.
# Il timeout invalida la prova se la finestra non compare.
timeout \
    --signal=TERM \
    60s \
    xdotool search \
    --sync \
    --onlyvisible \
    --all \
    --pid "$(cat firefox.pid)" \
    --class '[Ff]irefox' \
    > window.id

# La chiusura è separata e non entra nel tempo misurato.
