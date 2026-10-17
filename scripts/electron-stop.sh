#!/usr/bin/env bash
set -euo pipefail

## CHIUSURA DELLA SOLA ISTANZA DI BENCHMARK
cd -- "${BENCH_ROOT:?}/work/${BENCH_KERNEL:?}/${BENCH_APP:?}"
if [ ! -f app.pid ]; then
    exit 0
fi

# Il gruppo separato comprende anche i processi figli di App.
kill -TERM -- "-$(cat app.pid)" 2>/dev/null || true
for attempt in {1..100}; do
    if ! pgrep -g "$(cat app.pid)" -r R,S,D,T,I >/dev/null; then
        rm -f -- app.pid window.id
        exit 0
    fi
    sleep 0.1
done

# Una chiusura anomala invalida la sessione.
kill -KILL -- "-$(cat app.pid)" 2>/dev/null || true
echo 'App non si è chiuso entro 10 secondi: sessione interrotta.' >&2
exit 1
