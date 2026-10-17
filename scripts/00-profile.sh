#!/usr/bin/env bash
set -euo pipefail
umask 077

## PROFILO DI RIFERIMENTO — UNA SOLA VOLTA
cd -- "$(dirname -- "$0")/.."
mkdir -p work
cd work

# Non usare il profilo personale né ricreare quello di riferimento.
if pgrep -x firefox >/dev/null || [ -e profile-base ]; then
    echo 'Chiudi Firefox; se profile-base esiste, conserva il profilo già preparato.' >&2
    exit 1
fi
mkdir profile-base
cat > profile-base/user.js <<'EOF'
user_pref("browser.shell.checkDefaultBrowser", false);
user_pref("browser.startup.page", 0);
user_pref("browser.startup.homepage", "about:blank");
user_pref("browser.aboutwelcome.enabled", false);
user_pref("browser.startup.firstrunSkipsHomepage", true);
user_pref("browser.sessionstore.resume_from_crash", false);
EOF

# Aspetta la finestra vuota, poi chiudi Firefox normalmente.
echo 'Attendi about:blank, completa eventuali schermate iniziali e chiudi Firefox.'
firefox \
    --no-remote \
    --new-instance \
    --profile "$PWD/profile-base" \
    about:blank
touch profile-ready

# Conserva questa stessa cartella per tutti i kernel.
# Non pubblicare work/: contiene il profilo e i file temporanei.
