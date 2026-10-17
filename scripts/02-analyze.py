#!/usr/bin/env python3
"""Genera una tabella e una figura dai soli CSV misurati della fase 2."""

import csv
import io
import math
from pathlib import Path
from statistics import mean, median

## PERCORSI E KERNEL DEL PROTOCOLLO
root = Path(__file__).resolve().parent.parent
kernels = {
    "7.0.0-38-generic": "Mint 7.0.0-38",
    "7.2.9-kpl-efficiency": "efficiency",
    "7.2.9-kpl-thinlto": "thinlto",
    "7.2.9-kpl-reactive": "reactive",
    "7.2.9-kpl-reactive2": "reactive2",
}
baseline = "7.0.0-38-generic"
columns = ["kernel", "metric", "replicate", "elapsed_s", "value", "unit"]
summaries = {}

## LETTURA DEI DATI REALI
# Nessuna ricerca in work/: i CSV parziali non sono risultati validi.
for kernel in kernels:
    source = root / "results" / f"{kernel}.csv"
    if not source.exists():
        continue
    with source.open(newline="", encoding="utf-8") as handle:
        reader = csv.DictReader(handle)
        if reader.fieldnames != columns:
            raise SystemExit(f"Colonne non valide: {source.name}. Nessun output aggiornato.")
        rows = list(reader)

    ## CONTROLLI MINIMI CONTRO SESSIONI INCOMPLETE
    values = {"firefox_startup": {}, "idle_power": {}}
    elapsed = {}
    for row in rows:
        try:
            metric = row["metric"]
            replicate = int(row["replicate"])
            value = float(row["value"])
            if (None in row or row["kernel"] != kernel or metric not in values
                    or not math.isfinite(value) or value <= 0
                    or replicate in values[metric]):
                raise ValueError
            expected_unit = "s" if metric == "firefox_startup" else "W"
            if row["unit"] != expected_unit:
                raise ValueError
            if metric == "idle_power":
                seconds = float(row["elapsed_s"])
                if not math.isfinite(seconds) or seconds <= 0:
                    raise ValueError
                elapsed[replicate] = seconds
            elif row["elapsed_s"] != "":
                raise ValueError
            values[metric][replicate] = value
        except (ValueError, TypeError, KeyError):
            raise SystemExit(f"Riga non valida o duplicata: {source.name}. Nessun output aggiornato.")

    for metric, count in [("firefox_startup", 10), ("idle_power", 120)]:
        if set(values[metric]) != set(range(1, count + 1)):
            raise SystemExit(f"Sessione incompleta: {source.name}, {metric}. Nessun output aggiornato.")
    if any(elapsed[n] <= elapsed[n - 1] for n in range(2, 121)):
        raise SystemExit(f"Tempi non crescenti: {source.name}. Nessun output aggiornato.")
    # Tolleranza operativa dichiarata: al massimo 1 s rispetto alla scadenza.
    # Non elimina campioni e non li sostituisce con valori stimati.
    if any(abs(elapsed[n] - 5 * n) > 1 for n in range(1, 121)):
        raise SystemExit(f"Cadenza fuori protocollo: {source.name}. Controllare i tempi; nessun output aggiornato.")

    summaries[kernel] = (
        median(values["firefox_startup"].values()),
        mean(values["idle_power"].values()),
    )

if not summaries:
    raise SystemExit("Nessun CSV misurato disponibile. Tabella e figura non generate; eventuali output precedenti non aggiornati.")

## UNA TABELLA — DIFFERENZE RISPETTO A MINT
# Calcola sui valori completi; arrotonda soltanto la presentazione.
table = [
    "| Kernel | Median Firefox startup (s) | Change vs Mint (%) | Mean idle power (W) | Change vs Mint (%) |",
    "|---|---:|---:|---:|---:|",
]
for kernel, label in kernels.items():
    if kernel not in summaries:
        table.append(f"| {label} | Not measured | N/A | Not measured | N/A |")
        continue
    startup, watts = summaries[kernel]
    time_delta = power_delta = "N/A"
    if baseline in summaries:
        mint_startup, mint_watts = summaries[baseline]
        time_delta = f"{100 * (startup / mint_startup - 1):+.2f}"
        power_delta = f"{100 * (watts / mint_watts - 1):+.2f}"
    table.append(f"| {label} | {startup:.4f} | {time_delta} | {watts:.4f} | {power_delta} |")

notes = [
    "Negative changes mean lower startup time or lower idle power.",
    "Each measured kernel: 10 startup repetitions and 120 power samples from one session.",
    "Missing kernels have no plotted point. N/A means the comparison is unavailable.",
    "Mint is the installed baseline with the shared system tuning, not a pristine installation.",
    "Descriptive summaries only: no significance test or uncertainty estimate is supplied.",
    "Lower left is preferable on both measures; trade-offs do not define a unique winner.",
    "Idle power is not a direct measurement of battery runtime.",
]
if baseline not in summaries:
    notes.insert(0, "Mint baseline not measured: all percentage changes are unavailable.")
document = "\n".join(table) + "\n\n" + "\n\n".join(notes) + "\n"

## UNA FIGURA — TEMPO SULL'ASSE X, WATT SULL'ASSE Y
# Importa la sola dipendenza esterna dopo aver verificato la presenza dei dati.
try:
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
except ImportError:
    raise SystemExit("Matplotlib non disponibile. Nessun output aggiornato; installarlo prima dell'analisi.")

fig, ax = plt.subplots(figsize=(9, 6))
markers = ["o", "s", "^", "D", "P"]
colors = ["#333333", "#0072B2", "#D55E00", "#009E73", "#CC79A7"]
for (kernel, label), marker, color in zip(kernels.items(), markers, colors):
    if kernel not in summaries:
        continue
    startup, watts = summaries[kernel]
    ax.scatter(startup, watts, label=label, marker=marker, color=color,
               s=85, alpha=0.8, edgecolors="white", linewidths=0.6, zorder=3)

ax.set_xlabel("Median Firefox startup to visible window (s)")
ax.set_ylabel("Mean idle battery power (W)")
ax.set_title("Firefox startup under CPU load vs idle battery power")
ax.set_xlim(0, max(value[0] for value in summaries.values()) * 1.2)
ax.set_ylim(0, max(value[1] for value in summaries.values()) * 1.2)
ax.grid(alpha=0.2)
ax.spines[["top", "right"]].set_visible(False)
ax.legend(loc="upper left", bbox_to_anchor=(1.02, 1), frameon=False)
fig.text(0.08, 0.05,
         f"Measured kernels: {len(summaries)}/5. Lower left is preferable; no uncertainty shown.\n"
         "Coincident points may overlap. Unmeasured kernels are omitted.", fontsize=9)
fig.subplots_adjust(left=0.1, right=0.75, bottom=0.22, top=0.88)

## SALVATAGGIO — SOLO DOPO LETTURA E RENDERING RIUSCITI
image = io.BytesIO()
fig.savefig(image, format="png", dpi=180, facecolor="white")
plt.close(fig)
(root / "docs" / "figures").mkdir(parents=True, exist_ok=True)
(root / "docs" / "results-summary.md").write_text(document, encoding="utf-8")
(root / "docs" / "figures" / "kernel-tradeoff.png").write_bytes(image.getvalue())
print(document)
print("Salvati: docs/results-summary.md e docs/figures/kernel-tradeoff.png")

# Controlla tabella e figura prima di inserirle nel README.
# Rigenera gli output dagli stessi CSV: non modificare i punti a mano.
# Non scegliere un vincitore soltanto sulla base di differenze piccole.
