#!/usr/bin/env bash
set -euo pipefail
umask 077
export LC_ALL=C

## CARTELLE E PREREQUISITI
cd -- "$(dirname -- "$0")/.."
export BENCH_ROOT="$PWD"
export BENCH_KERNEL="$(uname -r)"
case "$BENCH_KERNEL" in
    7.0.0-38-generic|7.2.9-kpl-efficiency|7.2.9-kpl-thinlto|7.2.9-kpl-reactive|7.2.9-kpl-reactive2) ;;
    *) echo 'Kernel non previsto dal protocollo.' >&2; exit 1 ;;
esac
for tool in firefox hyperfine stress-ng xdotool python3 nmcli setsid timeout pgrep sudo; do
    command -v "$tool" >/dev/null
done
# Il formato JSON è quello di hyperfine 1.x, con --conclude disponibile.
hyperfine --version | grep -E '^hyperfine 1\.(1[5-9]|[2-9][0-9])\.'
[ "${XDG_SESSION_TYPE:-}" = x11 ]
[ "$EUID" -ne 0 ]
[ -f work/profile-ready ]
if pgrep -x firefox >/dev/null || pgrep -x stress-ng >/dev/null; then
    echo 'Chiudi Firefox e ogni stress-ng prima della sessione.' >&2
    exit 1
fi

# Una sola sessione per kernel; nessuna sovrascrittura automatica.
mkdir -p work results configs
mkdir "work/$BENCH_KERNEL"
mkdir -p "work/$BENCH_KERNEL/idle" "work/$BENCH_KERNEL/firefox"
[ ! -e "results/$BENCH_KERNEL.csv" ]
cd "work/$BENCH_KERNEL"

## METADATI SENZA IDENTIFICATIVI PERSONALI
uname -r > "$BENCH_ROOT/configs/$BENCH_KERNEL.txt"
# Salva solo i parametri ammessi; non conserva root, UUID o percorsi.
python3 - <<'PY' >> "$BENCH_ROOT/configs/$BENCH_KERNEL.txt"
from pathlib import Path
allowed = {"ro", "rw", "quiet", "splash", "preempt=lazy", "preempt=full",
           "preempt=none", "preempt=voluntary", "rcu_nocbs=all",
           "rcutree.enable_rcu_lazy=1", "rcutree.enable_rcu_lazy=0"}
tokens = Path('/proc/cmdline').read_text().split()
print('cmdline_filtered=' + ' '.join(t for t in tokens if t in allowed))
print('cmdline_omitted_tokens=' + str(sum(t not in allowed for t in tokens)))
PY
firefox --version >> "$BENCH_ROOT/configs/$BENCH_KERNEL.txt"
hyperfine --version >> "$BENCH_ROOT/configs/$BENCH_KERNEL.txt"
stress-ng --version >> "$BENCH_ROOT/configs/$BENCH_KERNEL.txt"
tar \
    --sort=name \
    --mtime=@0 \
    --owner=0 \
    --group=0 \
    --numeric-owner \
    -cf - \
    -C "$BENCH_ROOT/work" \
    profile-base | sha256sum | cut -d ' ' -f 1 \
    >> "$BENCH_ROOT/configs/$BENCH_KERNEL.txt"

## CONDIZIONI COMUNI
# Questo hardware ha una batteria e un controllo di luminosità.
set -- /sys/class/power_supply/BAT*
[ "$#" -eq 1 ]
BATTERY="$1"
set -- /sys/class/backlight/*
[ "$#" -eq 1 ]
BACKLIGHT="$1"
BRIGHTNESS="$(cat "$BACKLIGHT/brightness")"
export BATTERY BACKLIGHT BRIGHTNESS
grep -qx Discharging "$BATTERY/status"
nmcli radio wifi | grep -qx enabled
if [ -r "$BATTERY/power_now" ]; then
    POWER_SOURCE=power_now
else
    [ -r "$BATTERY/current_now" ]
    [ -r "$BATTERY/voltage_now" ]
    POWER_SOURCE=current_voltage
fi
printf 'brightness=%s/%s\npower_source=%s\n' \
    "$BRIGHTNESS" "$(cat "$BACKLIGHT/max_brightness")" "$POWER_SOURCE" \
    >> "$BENCH_ROOT/configs/$BENCH_KERNEL.txt"
echo 'Solo il terminale aperto; chiudi anche Codex/ChatGPT e gli altri programmi.'
echo 'Usa la stessa luminosità, schermi collegati e Wi-Fi per tutti i kernel.'
echo 'Disabilita manualmente oscuramento/sospensione e attendi il raffreddamento.'
read -r -p 'Condizioni pronte, alimentatore scollegato? Scrivi MISURA: ' READY
[ "$READY" = MISURA ]

## BATTERIA — 120 CAMPIONI IN 10 MINUTI
cd idle
# Assestamento minimo; non dimostra equilibrio termico.
sleep 120
printf 'kernel,metric,replicate,elapsed_s,value,unit\n' > ../measurements.partial.csv
START="$(cut -d ' ' -f 1 /proc/uptime)"
for SAMPLE in {1..120}; do
    # Scadenze assolute: 5, 10, ..., 600 secondi.
    sleep "$(awk -v start="$START" -v n="$SAMPLE" \
        '{d=start+5*n-$1; print (d>0 ? d : 0)}' /proc/uptime)"
    grep -qx Discharging "$BATTERY/status"
    [ "$(cat "$BACKLIGHT/brightness")" = "$BRIGHTNESS" ]
    if [ "$POWER_SOURCE" = power_now ]; then
        WATTS="$(awk '{printf "%.6f", $1/1000000}' "$BATTERY/power_now")"
    else
        WATTS="$(awk 'NR==1 {i=$1; next} {printf "%.6f", i*$1/1000000000000}' \
            "$BATTERY/current_now" "$BATTERY/voltage_now")"
    fi
    awk -v kernel="$BENCH_KERNEL" -v n="$SAMPLE" -v start="$START" -v watts="$WATTS" \
        '{printf "%s,idle_power,%d,%.2f,%s,W\n", kernel,n,$1-start,watts}' \
        /proc/uptime >> ../measurements.partial.csv
done
nmcli radio wifi | grep -qx enabled
head ../measurements.partial.csv

## FIREFOX — 10 AVVII A FREDDO SOTTO CARICO
cd ../firefox
# Autenticazione dopo la misura a riposo, prima di avviare il carico.
sudo -v
setsid stress-ng \
    --cpu 8 \
    --cpu-method int64 \
    --timeout 15m \
    > stress.log 2>&1 &
STRESS_PID=$!
export STRESS_PID
trap 'STATUS=$?; set +e; bash "$BENCH_ROOT/scripts/firefox-stop.sh"; kill -TERM -- "-$STRESS_PID" 2>/dev/null; wait "$STRESS_PID" 2>/dev/null; exit "$STATUS"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
sleep 10
kill -0 "$STRESS_PID"
[ "$(pgrep -P "$STRESS_PID" | wc -l)" -eq 8 ]

hyperfine \
    --runs 10 \
    --shell bash \
    --prepare 'bash "$BENCH_ROOT/scripts/firefox-prepare.sh"' \
    --conclude 'bash "$BENCH_ROOT/scripts/firefox-stop.sh"' \
    --export-json timings.json \
    'bash "$BENCH_ROOT/scripts/firefox-start.sh"'

kill -0 "$STRESS_PID"
[ "$(pgrep -P "$STRESS_PID" | wc -l)" -eq 8 ]
grep -qx Discharging "$BATTERY/status"
[ "$(cat "$BACKLIGHT/brightness")" = "$BRIGHTNESS" ]
nmcli radio wifi | grep -qx enabled
kill -TERM -- "-$STRESS_PID"
wait "$STRESS_PID" || true
trap - EXIT INT TERM

## CSV UNICO PER KERNEL
# Estrae i tempi individuali: il CSV nativo di hyperfine contiene riepiloghi.
python3 - <<'PY'
import csv
import json
import os
from pathlib import Path

result = json.loads(Path('timings.json').read_text())['results'][0]
if len(result['times']) != 10 or any(result['exit_codes']):
    raise SystemExit('Sessione incompleta: CSV finale non creato.')
with Path('../measurements.partial.csv').open('a', newline='') as handle:
    writer = csv.writer(handle)
    for n, seconds in enumerate(result['times'], 1):
        writer.writerow([os.environ['BENCH_KERNEL'], 'firefox_startup', n, '', seconds, 's'])
PY
cp ../measurements.partial.csv "$BENCH_ROOT/results/$BENCH_KERNEL.csv"
head "$BENCH_ROOT/results/$BENCH_KERNEL.csv"
cut -d , -f 2 "$BENCH_ROOT/results/$BENCH_KERNEL.csv" | uniq -c
wc -l "$BENCH_ROOT/results/$BENCH_KERNEL.csv"

# Attesi: intestazione + 120 campioni di potenza + 10 tempi di avvio.
# Prima del prossimo kernel: controlla i dati e chiedi conferma del riavvio.
# Non eseguire grub-reboot o reboot automaticamente.
