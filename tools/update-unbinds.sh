#!/usr/bin/env bash
# Erzeugt den "Kollisionen entfernen"-Block in omarchy-keybindings.conf neu,
# passend zu allen bind*-Zeilen der Datei. Nach Änderungen an Bindings ausführen.
set -euo pipefail
file="$(cd "$(dirname "$0")/.." && pwd)/omarchy-keybindings.conf"
start='^# BEGIN UNBINDS$'
end='^# END UNBINDS$'

unbinds=$(awk -F',' '
  /^bind[a-z]* *=/ {
    sub(/^bind[a-z]* *= */, "", $1)
    mods = $1; key = $2
    gsub(/^ +| +$/, "", mods); gsub(/^ +| +$/, "", key)
    id = mods "," key
    if (!(id in seen)) { seen[id] = 1; printf "unbind = %s, %s\n", mods, key }
  }' "$file")

awk -v block="$unbinds" -v s="$start" -v e="$end" '
  $0 ~ s { print; print block; skip = 1; next }
  $0 ~ e { skip = 0 }
  !skip { print }' "$file" > "$file.tmp"
mv "$file.tmp" "$file"
echo "$(printf '%s\n' "$unbinds" | wc -l) unbind-Zeilen geschrieben."
