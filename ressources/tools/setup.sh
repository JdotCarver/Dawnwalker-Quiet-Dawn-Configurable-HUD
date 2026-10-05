#!/usr/bin/env bash
# ressources/tools/setup.sh
#
# Install what the checking tools need. Safe to re-run.
#
# Run this at the start of a turn whenever check-lua.py or
# test-settings-migration.py reports that lupa is missing.
#
# Why it keeps being missing: pip installs land in ~/.local, which the Arena
# sandbox excludes from its snapshots. Every snapshot restore therefore wipes
# the install while leaving the repository intact, so a tool that worked ten
# minutes ago suddenly does not.
#
# --break-system-packages is required because the sandbox ships an
# externally-managed Python (PEP 668) and there is no virtualenv here.

set -uo pipefail

echo "== installing Lua tooling =="
pip install --quiet --break-system-packages lupa || {
    echo "!! pip install failed"
    exit 1
}

python3 - <<'PY'
from lupa import lua54
print("== lupa ready:", lua54.LuaRuntime().eval("_VERSION"))
PY
