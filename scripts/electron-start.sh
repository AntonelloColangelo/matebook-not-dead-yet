#!/usr/bin/env bash
set -euo pipefail

## PRIMA FINESTRA VISIBILE
cd -- "${BENCH_ROOT:?}/work/${BENCH_KERNEL:?}/${BENCH_APP:?}"
case "$BENCH_APP" in
    claude) APP=claude-desktop ;;
    codex) APP=chatgpt ;;
    *) exit 1 ;;
esac
# Le cartelle personali non vengono usate come profilo di prova.
export XDG_CONFIG_HOME="$PWD/profile/config"
export XDG_CACHE_HOME="$PWD/profile/cache"
export XDG_DATA_HOME="$PWD/profile/data"
export CLAUDE_CONFIG_DIR="$PWD/profile/claude"
setsid "$APP" \
    --user-data-dir="$PWD/profile/user-data" \
    --ozone-platform=x11 \
    > app.log 2>&1 &
echo "$!" > app.pid

# Cerca soltanto finestre visibili del processo appena avviato.
timeout \
    --signal=TERM \
    60s \
    xdotool search \
    --sync \
    --onlyvisible \
    --pid "$(cat app.pid)" \
    > window.id

# Anche una finestra di accesso conta; non misura il caricamento della chat.
