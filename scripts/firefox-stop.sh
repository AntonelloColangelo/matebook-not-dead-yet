#!/usr/bin/env bash
set -euo pipefail

## CHIUSURA DELLA SOLA ISTANZA DI BENCHMARK
cd -- "${BENCH_ROOT:?}/work/${BENCH_KERNEL:?}/firefox"
if [ ! -f firefox.pid ]; then
    exit 0
fi

# Il gruppo separato comprende anche i processi figli di Firefox.
kill -TERM -- "-$(cat firefox.pid)" 2>/dev/null || true
for attempt in {1..100}; do
    if ! pgrep -g "$(cat firefox.pid)" -r R,S,D,T,I >/dev/null; then
        rm -f -- firefox.pid window.id
        exit 0
    fi
    sleep 0.1
done

# Una chiusura anomala invalida la sessione.
kill -KILL -- "-$(cat firefox.pid)" 2>/dev/null || true
echo 'Firefox non si è chiuso entro 10 secondi: sessione interrotta.' >&2
exit 1
