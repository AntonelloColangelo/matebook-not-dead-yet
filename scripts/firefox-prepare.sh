#!/usr/bin/env bash
set -euo pipefail

## CACHE FREDDA
# Hyperfine esegue questa preparazione fuori dal tempo misurato.
cd -- "${BENCH_ROOT:?}/work/${BENCH_KERNEL:?}/firefox"
kill -0 "${STRESS_PID:?}"
[ "$(pgrep -P "$STRESS_PID" | wc -l)" -eq 8 ]
grep -qx Discharging "${BATTERY:?}/status"
[ "$(cat "${BACKLIGHT:?}/brightness")" = "${BRIGHTNESS:?}" ]
bash "$BENCH_ROOT/scripts/firefox-stop.sh"
rm -rf -- profile
cp -a -- "$BENCH_ROOT/work/profile-base" profile
sync
sudo -n sh -c 'echo 3 > /proc/sys/vm/drop_caches'

# Non usare warmup: ogni ripetizione deve partire con cache svuotata.
