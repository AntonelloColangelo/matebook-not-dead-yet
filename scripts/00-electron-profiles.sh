#!/usr/bin/env bash
set -euo pipefail
umask 077

## PROFILI DI PROVA — SOLO QUANDO RIPRENDEREMO
cd -- "$(dirname -- "$0")/.."
mkdir -p work
cd work
# Esci dalle app anche nell'area di notifica prima di continuare.
if pgrep -x ChatGPT >/dev/null || pgrep -x claude-desktop >/dev/null; then
    echo 'Chiudi completamente Claude e Codex prima di preparare i profili.' >&2
    exit 1
fi
for APP in claude codex; do
    if [ -f "$APP-profile-ready" ]; then
        echo "Profilo $APP già pronto: conservato."
        continue
    fi
    if [ -e "$APP-profile-base" ]; then
        echo "Preparazione $APP incompleta: controlla la cartella prima di riprovare." >&2
        exit 1
    fi
    (
        case "$APP" in
            claude) COMMAND=claude-desktop ;;
            codex) COMMAND=chatgpt ;;
        esac
        command -v "$COMMAND" >/dev/null
        mkdir "$APP-profile-base"
        cd "$APP-profile-base"
        mkdir -p config cache data codex claude user-data
        export XDG_CONFIG_HOME="$PWD/config"
        export XDG_CACHE_HOME="$PWD/cache"
        export XDG_DATA_HOME="$PWD/data"
        export CLAUDE_CONFIG_DIR="$PWD/claude"
        echo "Profilo di prova $APP: non accedere. Attendi la finestra, poi esci completamente dall'app."
        "$COMMAND" \
            --user-data-dir="$PWD/user-data" \
            --ozone-platform=x11
        touch ../"$APP-profile-ready"
    )
done

# Conserva i due profili per tutti i kernel e non pubblicare work/.
# La preparazione non misura tempi. Non eseguirla mentre i test sono sospesi.
