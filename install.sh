#!/usr/bin/env bash
# Installiert die Omarchy-Keybindings in ein normales Hyprland
# (hyprland.lua -> omarchy-keybindings.lua, sonst omarchy-keybindings.conf).
#
#   curl -fsSL https://raw.githubusercontent.com/mandelbrot1122/omarchy-hacks/HEAD/install.sh | bash
#
# Optionen:
#   --install-deps   fehlende Pakete installieren (nur Arch/pacman)
#   --no-detect      Programme nicht automatisch erkennen, Standardwerte behalten
#   --uninstall      Keybindings wieder entfernen
set -euo pipefail

REPO="mandelbrot1122/omarchy-hacks"
RAW_BASE="https://raw.githubusercontent.com/$REPO/HEAD"
HYPR_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/hypr"

# Hyprland mit hyprland.lua bekommt die Lua-Version, sonst die .conf-Version.
if [[ -f $HYPR_DIR/hyprland.lua ]]; then
  MODE=lua
  TARGET="$HYPR_DIR/omarchy-keybindings.lua"
  MAIN="$HYPR_DIR/hyprland.lua"
  MARKER="-- omarchy-keybindings"
  INCLUDE="dofile(\"$TARGET\")"
else
  MODE=conf
  TARGET="$HYPR_DIR/omarchy-keybindings.conf"
  MAIN="$HYPR_DIR/hyprland.conf"
  MARKER="# omarchy-keybindings"
  INCLUDE="source = $TARGET"
fi
FILE_NAME="omarchy-keybindings.$MODE"

install_deps=false
detect=true
uninstall=false
for arg in "$@"; do
  case "$arg" in
    --install-deps) install_deps=true ;;
    --no-detect) detect=false ;;
    --uninstall) uninstall=true ;;
    -h | --help) sed -n '2,10p' "$0" 2>/dev/null || true; exit 0 ;;
    *) echo "Unbekannte Option: $arg" >&2; exit 1 ;;
  esac
done

info() { printf '\033[1;34m::\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }
have() { command -v "$1" >/dev/null 2>&1; }

reload_hyprland() {
  if have hyprctl && [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]]; then
    hyprctl reload >/dev/null && info "Hyprland neu geladen."
    local errors
    errors=$(hyprctl configerrors 2>/dev/null | grep -v '^\s*$' || true)
    if [[ -n $errors ]]; then
      warn "Hyprland meldet Konfigurationsfehler:"
      printf '%s\n' "$errors" >&2
    fi
  fi
}

# ---------------------------------------------------------------- Deinstallation
if $uninstall; then
  if [[ -f $MAIN ]]; then
    cp "$MAIN" "$MAIN.bak"
    grep -vF -e "$MARKER" -e "$INCLUDE" "$MAIN.bak" >"$MAIN" || true
    info "Einbindung aus $MAIN entfernt (Sicherung: $MAIN.bak)."
  fi
  if [[ -f $TARGET ]]; then
    mv "$TARGET" "$TARGET.bak"
    info "$TARGET nach $TARGET.bak verschoben."
  fi
  reload_hyprland
  exit 0
fi

# ---------------------------------------------------------------- Datei holen
mkdir -p "$HYPR_DIR"
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || echo "")
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

info "Hyprland-Konfiguration: $MAIN ($MODE)"
if [[ -n $script_dir && -f $script_dir/$FILE_NAME ]]; then
  cp "$script_dir/$FILE_NAME" "$tmp"
  info "Verwende lokale Datei $script_dir/$FILE_NAME."
elif have curl; then
  curl -fsSL "$RAW_BASE/$FILE_NAME" -o "$tmp"
elif have wget; then
  wget -qO "$tmp" "$RAW_BASE/$FILE_NAME"
else
  warn "Weder curl noch wget gefunden."; exit 1
fi

if [[ $MODE == lua ]]; then
  grep -q '^local function bind' "$tmp"
else
  grep -q '^bindd' "$tmp"
fi || { warn "Heruntergeladene Datei sieht falsch aus."; exit 1; }

# ---------------------------------------------------------------- Programme erkennen
set_var() { # set_var name wert
  if [[ $MODE == lua ]]; then
    awk -v name="$1" -v value="$2" '
      index($0, "  " name " = [[") == 1 { print "  " name " = [[" value "]],"; next }
      { print }' "$tmp" >"$tmp.new"
  else
    awk -v name="$1" -v value="$2" '
      index($0, "$" name " = ") == 1 { print "$" name " = " value; next }
      { print }' "$tmp" >"$tmp.new"
  fi
  mv "$tmp.new" "$tmp"
  printf '   %-18s %s\n' "\$$1" "$2"
}
first() { for c in "$@"; do have "${c%% *}" && { echo "$c"; return; }; done; return 1; }

if $detect; then
  info "Erkannte Programme:"

  terminal=$(first kitty alacritty ghostty foot wezterm konsole xterm || echo kitty)
  set_var terminal "$terminal"

  browser=$(first firefox librewolf zen-browser chromium brave google-chrome-stable vivaldi-stable || echo xdg-open)
  case "$browser" in
    firefox | librewolf | zen-browser) private="$browser --private-window" ;;
    xdg-open) private="xdg-open" ;;
    *) private="$browser --incognito" ;;
  esac
  set_var browser "$browser"
  set_var privateBrowser "$private"

  if chromium=$(first chromium brave google-chrome-stable vivaldi-stable microsoft-edge-stable helium-browser); then
    set_var webapp "sh -c 'exec $chromium --new-window --app=\"\$1\"' _"
  else
    set_var webapp "xdg-open"
  fi

  if have nautilus; then fm="nautilus --new-window"
  elif fm=$(first thunar dolphin nemo pcmanfm-qt pcmanfm); then :
  elif have yazi; then fm="$terminal -e yazi"
  else fm="xdg-open \"\$HOME\""; fi
  set_var fileManager "$fm"

  if have nvim; then editor="$terminal -e nvim"
  elif editor=$(first code zeditor gnome-text-editor kate gedit); then :
  elif have vim; then editor="$terminal -e vim"
  else editor="$terminal -e nano"; fi
  set_var editor "$editor"

  if have walker; then launcher="walker"; dmenu="walker --dmenu"
  elif have fuzzel; then launcher="fuzzel"; dmenu="fuzzel --dmenu"
  elif have rofi; then launcher="rofi -show drun"; dmenu="rofi -dmenu"
  else launcher="wofi --show drun"; dmenu="wofi --dmenu"; fi
  set_var launcher "$launcher"
  set_var dmenu "$dmenu"

  emoji=$(first rofimoji bemoji smile || echo "notify-send 'Kein Emoji-Picker installiert' 'z. B. rofimoji oder bemoji installieren'")
  set_var emojiPicker "$emoji"

  if calc=$(first gnome-calculator qalculate-gtk kcalc); then :
  elif have qalc; then calc="$terminal -e qalc"
  else calc="gnome-calculator"; fi
  set_var calculator "$calc"

  if have wiremix; then audio="$terminal -e wiremix"
  else audio=$(first pavucontrol pwvucontrol || echo pavucontrol); fi
  set_var audioControl "$audio"

  if have bluetui; then bt="$terminal -e bluetui"
  else bt=$(first blueman-manager blueberry overskride || echo blueman-manager); fi
  set_var bluetoothControl "$bt"

  if have impala; then net="$terminal -e impala"
  elif have nm-connection-editor; then net="nm-connection-editor"
  else net="$terminal -e nmtui"; fi
  set_var networkControl "$net"
fi

# ---------------------------------------------------------------- Datei installieren
if [[ -f $TARGET ]] && ! cmp -s "$tmp" "$TARGET"; then
  cp "$TARGET" "$TARGET.bak"
  info "Vorhandene Datei gesichert: $TARGET.bak"
fi
cp "$tmp" "$TARGET"
info "Installiert: $TARGET"

if ! grep -qF "$INCLUDE" "$MAIN" 2>/dev/null; then
  [[ -f $MAIN ]] && cp "$MAIN" "$MAIN.bak"
  printf '\n%s (https://github.com/%s)\n%s\n' "$MARKER" "$REPO" "$INCLUDE" >>"$MAIN"
  info "Am Ende von $MAIN eingebunden: $INCLUDE"
else
  info "$MAIN bindet die Datei bereits ein."
fi

# ---------------------------------------------------------------- Abhängigkeiten
# Befehl -> Arch-Paket
declare -A pkgs=(
  [hyprctl]=hyprland [jq]=jq [wpctl]=wireplumber [brightnessctl]=brightnessctl
  [playerctl]=playerctl [grim]=grim [slurp]=slurp [wl-copy]=wl-clipboard
  [cliphist]=cliphist [hyprpicker]=hyprpicker [hyprlock]=hyprlock
  [hypridle]=hypridle [wf-recorder]=wf-recorder [tesseract]=tesseract
  [notify-send]=libnotify [curl]=curl
)
missing_cmds=() missing_pkgs=()
for cmd in "${!pkgs[@]}"; do
  have "$cmd" || { missing_cmds+=("$cmd"); missing_pkgs+=("${pkgs[$cmd]}"); }
done
if $detect && ! have "${dmenu%% *}"; then
  missing_cmds+=("${dmenu%% *}"); missing_pkgs+=("${dmenu%% *}")
fi

if ((${#missing_cmds[@]})); then
  warn "Fehlende Befehle: ${missing_cmds[*]}"
  if $install_deps && have pacman; then
    [[ " ${missing_pkgs[*]} " == *" tesseract "* ]] && missing_pkgs+=(tesseract-data-eng tesseract-data-deu)
    sudo pacman -S --needed "${missing_pkgs[@]}" </dev/tty
  else
    warn "Arch: sudo pacman -S --needed ${missing_pkgs[*]}"
    warn "(oder dieses Skript mit --install-deps ausführen)"
  fi
fi

reload_hyprland
info "Fertig. SUPER + K zeigt alle Tastenkürzel."
