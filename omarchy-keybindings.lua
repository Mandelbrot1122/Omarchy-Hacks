-- ============================================================================
--  Omarchy-Keybindings für normales Hyprland (Lua-Konfiguration)
-- ============================================================================
--  Alle Tastenkürzel von Omarchy (https://github.com/basecamp/omarchy) in einer
--  Datei, ohne die omarchy-*-Skripte. Für Hyprland mit hyprland.lua.
--  (Für das klassische hyprland.conf gibt es omarchy-keybindings.conf.)
--
--  Einbinden: als LETZTE Zeile in ~/.config/hypr/hyprland.lua
--      dofile(os.getenv("HOME") .. "/.config/hypr/omarchy-keybindings.lua")
--
--  Vor jedem Binding wird eine vorher definierte Belegung derselben Taste
--  entfernt. Eigene Bindings, die gewinnen sollen, NACH dem dofile() setzen.
--
--  Alle Bindings anzeigen: SUPER + K
-- ============================================================================


-- ----------------------------------------------------------------------------
--  Programme (install.sh setzt diese automatisch nach dem, was installiert ist)
-- ----------------------------------------------------------------------------
local apps = {
  terminal = [[kitty]],
  browser = [[firefox]],
  privateBrowser = [[firefox --private-window]],
  fileManager = [[nautilus --new-window]],
  editor = [[kitty -e nvim]],
  launcher = [[wofi --show drun]],
  dmenu = [[wofi --dmenu]],
  emojiPicker = [[rofimoji]],
  calculator = [[gnome-calculator]],
  audioControl = [[pavucontrol]],
  bluetoothControl = [[blueman-manager]],
  networkControl = [[nm-connection-editor]],
  webapp = [[sh -c 'exec chromium --new-window --app="$1"' _]],
}


-- ----------------------------------------------------------------------------
--  Hilfsfunktionen
-- ----------------------------------------------------------------------------
local errors = {}
local unbound = {}

local function bind(keys, description, action, options)
  -- Eine vorher (z. B. in hyprland.lua) definierte Belegung derselben Taste
  -- entfernen, aber nur einmal: mehrere Bindings dieser Datei auf einer Taste
  -- (ALT + TAB) sollen alle bestehen bleiben.
  if not unbound[keys] then
    unbound[keys] = true
    pcall(hl.unbind, keys)
  end

  local opts = {}
  for k, v in pairs(options or {}) do
    opts[k] = v
  end
  opts.description = description

  if type(action) == "string" then
    action = hl.dsp.exec_cmd(action)
  end

  local ok, err = pcall(hl.bind, keys, action, opts)
  if not ok then
    table.insert(errors, keys .. ": " .. tostring(err))
  end
end

-- Ein Abschnitt, der fehlschlägt (z. B. wegen einer API-Änderung in Hyprland),
-- nimmt die anderen nicht mit.
local function section(name, fn)
  local ok, err = pcall(fn)
  if not ok then
    table.insert(errors, name .. ": " .. tostring(err))
  end
end

local function sh_quote(value)
  return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

local function webapp(url)
  return apps.webapp .. " " .. sh_quote(url)
end

local function in_terminal(command)
  return apps.terminal .. " -e " .. command
end

local function active_address()
  local window = hl.get_active_window()
  return window and window.address and ("address:" .. window.address) or nil
end

-- Taste an das aktive Fenster senden. Erst runter, kurz danach hoch, sonst
-- bleibt die synthetische Taste in manchen Hyprland-Versionen hängen.
local function send_shortcut(mods, key)
  return function()
    hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "down" }))
    hl.timer(function()
      hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "up" }))
    end, { timeout = 50, type = "oneshot" })
  end
end

local function dispatch(fn)
  return function()
    hl.dispatch(fn())
  end
end


-- ----------------------------------------------------------------------------
--  Shell-Befehle
-- ----------------------------------------------------------------------------
local cmd = {}

cmd.screenshot = [[sel=$(slurp -d) && mkdir -p "$HOME/Pictures" && grim -g "$sel" - | tee "$HOME/Pictures/Screenshot_$(date +%Y-%m-%d_%H-%M-%S).png" | wl-copy && notify-send "Screenshot" "Gespeichert und kopiert"]]

local function screenrecord(extra, title)
  return [[pkill -INT -x wf-recorder || { sel=$(slurp -d) && mkdir -p "$HOME/Videos" && notify-send "]] .. title .. [[" "Gleiche Taste erneut drücken zum Stoppen" && wf-recorder ]] .. extra .. [[ -g "$sel" -f "$HOME/Videos/Aufnahme_$(date +%Y-%m-%d_%H-%M-%S).mp4"; }]]
end
cmd.screenrecord = screenrecord("", "Bildschirmaufnahme")
cmd.screenrecordAudio = screenrecord("--audio", "Bildschirmaufnahme (mit Ton)")

cmd.ocr = [[sel=$(slurp -d) && grim -g "$sel" - | tesseract stdin stdout 2>/dev/null | wl-copy && notify-send "Text erkannt" "In die Zwischenablage kopiert"]]

cmd.clipboard = "cliphist list | " .. apps.dmenu .. " | cliphist decode | wl-copy"

cmd.power = [[case "$(printf 'Sperren\nAbmelden\nBereitschaft\nNeustart\nHerunterfahren' | ]] .. apps.dmenu .. [[)" in Sperren) hyprlock ;; Abmelden) hyprctl dispatch 'hl.dsp.exit()' || hyprctl dispatch exit ;; Bereitschaft) systemctl suspend ;; Neustart) systemctl reboot ;; Herunterfahren) systemctl poweroff ;; esac]]

cmd.keybindings = [[hyprctl binds -j | jq -r '.[] | select(.description != null and .description != "") | [([if ((.modmask / 64 | floor) % 2) == 1 then "SUPER" else empty end, if ((.modmask / 4 | floor) % 2) == 1 then "CTRL" else empty end, if ((.modmask / 8 | floor) % 2) == 1 then "ALT" else empty end, if (.modmask % 2) == 1 then "SHIFT" else empty end, (if .key != "" then .key elif (.keycode >= 10 and .keycode <= 19) then ((.keycode - 9) % 10 | tostring) elif .keycode == 49 then "^" elif .keycode == 20 then "-" elif .keycode == 21 then "=" else "code:" + (.keycode | tostring) end)] | join(" + ")), .description] | "\(.[0])\t\(.[1])"' | awk -F '\t' '!seen[$0]++ { printf "%-32s %s\n", $1, $2 }' | ]] .. apps.dmenu

cmd.fileManagerCwd = [[pid=$(hyprctl activewindow -j | jq -r '.pid'); child=$(pgrep -P "$pid" | tail -n1); cd "$(readlink "/proc/${child:-$pid}/cwd" 2>/dev/null || echo "$HOME")" && ]] .. apps.fileManager .. " ."

cmd.tiledFullscreen = [[if [ "$(hyprctl activewindow -j | jq -r '.fullscreenClient // 0')" = 2 ]; then hyprctl dispatch 'hl.dsp.window.fullscreen_state({ internal = 0, client = 0 })'; else hyprctl dispatch 'hl.dsp.window.fullscreen_state({ internal = 0, client = 2 })'; fi]]

cmd.idle = [[if pgrep -x hypridle >/dev/null; then pkill -x hypridle; notify-send "Sperre bei Inaktivität" "Aus"; else setsid -f hypridle >/dev/null 2>&1; notify-send "Sperre bei Inaktivität" "An"; fi]]

cmd.notifyDismiss = "makoctl dismiss 2>/dev/null || swaync-client --close-latest"
cmd.volumeUp = "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"
cmd.volumeDown = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
cmd.kbdUp = "brightnessctl -d '*::kbd_backlight' set 33%+"
cmd.kbdDown = "brightnessctl -d '*::kbd_backlight' set 33%-"


-- ----------------------------------------------------------------------------
--  Lua-Aktionen
-- ----------------------------------------------------------------------------
local act = {}

function act.close_all()
  for _, window in ipairs(hl.get_windows() or {}) do
    if window.address then
      hl.dispatch(hl.dsp.window.close({ window = "address:" .. window.address }))
    end
  end
end

-- Fenster herauslösen: schwebend, angepinnt und mittig (nochmal = zurück)
function act.pop()
  local window = active_address()
  if not window then return end
  hl.dispatch(hl.dsp.window.float({ action = "toggle", window = window }))
  hl.dispatch(hl.dsp.window.pin({ window = window }))
  hl.dispatch(hl.dsp.window.center({ window = window }))
end

local layouts = { "dwindle", "scrolling", "master" }
local function cycle_layout(step)
  return function()
    local current = hl.get_config("general.layout") or "dwindle"
    local index = 1
    for i, name in ipairs(layouts) do
      if name == current then index = i end
    end
    local next_layout = layouts[(index - 1 + step) % #layouts + 1]
    hl.config({ general = { layout = next_layout } })
    hl.exec_cmd("notify-send 'Layout' " .. sh_quote(next_layout))
  end
end

-- Abstände aus: alles auf 0. Abstände an: Konfiguration neu laden.
local gaps_off = false
function act.toggle_gaps()
  if gaps_off then
    gaps_off = false
    hl.exec_cmd("hyprctl reload")
  else
    gaps_off = true
    hl.config({
      general = { gaps_in = 0, gaps_out = 0, border_size = 0 },
      decoration = { rounding = 0 },
    })
  end
end

function act.toggle_opaque()
  local window = active_address()
  if window then
    hl.dispatch(hl.dsp.window.set_prop({ window = window, prop = "opaque", value = "toggle" }))
  end
end

-- Quake-Konsole: beim ersten Öffnen ein Terminal starten
function act.qconsole()
  hl.dispatch(hl.dsp.workspace.toggle_special("qconsole"))
  local ws = hl.get_workspace("special:qconsole")
  if ws and ws.visible and #(hl.get_workspace_windows("special:qconsole") or {}) == 0 then
    hl.exec_cmd(apps.terminal)
  end
end

local function workspace_to_monitor(direction)
  return function()
    local target = hl.get_monitor(direction)
    if target then
      hl.dispatch(hl.dsp.workspace.move({ monitor = target.name }))
    end
  end
end

local function window_to_monitor(direction)
  return function()
    local target = hl.get_monitor(direction)
    if target then
      hl.dispatch(hl.dsp.window.move({ monitor = target.name }))
    end
  end
end

-- Laptop-Bildschirm aus (nur wenn ein weiterer Monitor da ist) / wieder an
function act.toggle_laptop_display()
  local monitors = hl.get_monitors() or {}
  local internal
  for _, monitor in ipairs(monitors) do
    if monitor.name and (monitor.name:match("^eDP") or monitor.name:match("^LVDS") or monitor.name:match("^DSI")) then
      internal = monitor.name
    end
  end
  if internal and #monitors > 1 then
    hl.monitor({ output = internal, disabled = true })
  else
    hl.exec_cmd("hyprctl reload")
  end
end

function act.zoom_in()
  local zoom = hl.get_config("cursor.zoom_factor") or 1
  hl.config({ cursor = { zoom_factor = zoom + 1 } })
end

function act.zoom_reset()
  hl.config({ cursor = { zoom_factor = 1 } })
end


-- ----------------------------------------------------------------------------
--  Autostart (für Zwischenablage-Verlauf und Mediaplayer-Wechsel)
-- ----------------------------------------------------------------------------
section("Autostart", function()
  hl.on("hyprland.start", function()
    hl.exec_cmd("wl-paste --watch cliphist store")
    hl.exec_cmd("playerctld daemon")
  end)
end)


-- ============================================================================
--  Programme
-- ============================================================================
section("Programme", function()
  bind("SUPER + RETURN", "Terminal", apps.terminal)
  bind("SUPER + SHIFT + RETURN", "Browser", apps.browser)
  bind("SUPER + SHIFT + B", "Browser", apps.browser)
  bind("SUPER + SHIFT + ALT + B", "Browser (privat)", apps.privateBrowser)
  bind("SUPER + SHIFT + F", "Dateimanager", apps.fileManager)
  bind("SUPER + ALT + SHIFT + F", "Dateimanager im aktuellen Ordner", cmd.fileManagerCwd)
  bind("SUPER + SHIFT + N", "Editor", apps.editor)
  bind("SUPER + ALT + RETURN", "Tmux", in_terminal("tmux new-session -A -s Work"))
  bind("SUPER + SHIFT + Q", "Taschenrechner", apps.calculator)
  bind("XF86Calculator", "Taschenrechner", apps.calculator)
  bind("SUPER + SHIFT + D", "Docker (lazydocker)", in_terminal("lazydocker"))
  bind("SUPER + SHIFT + O", "Obsidian", "obsidian")
  bind("SUPER + SHIFT + slash", "Passwörter (1Password)", "1password")
  bind("SUPER + SHIFT + T", "Systemmonitor (btop)", in_terminal("btop"))

  -- Apps und Web-Apps (Omarchy-Standard, Region "global")
  bind("SUPER + SHIFT + M", "Musik (Spotify)", "spotify")
  bind("SUPER + SHIFT + G", "Signal", "signal-desktop")
  bind("SUPER + SHIFT + A", "ChatGPT", webapp("https://chatgpt.com"))
  bind("SUPER + SHIFT + ALT + A", "Grok", webapp("https://grok.com"))
  bind("SUPER + SHIFT + C", "Kalender (HEY)", webapp("https://app.hey.com/calendar/weeks/"))
  bind("SUPER + SHIFT + E", "E-Mail (HEY)", webapp("https://app.hey.com"))
  bind("SUPER + SHIFT + ALT + E", "Neue E-Mail (HEY)", webapp("https://app.hey.com/messages/new?display=standalone&new_window=true"))
  bind("SUPER + SHIFT + Y", "YouTube", webapp("https://youtube.com/"))
  bind("SUPER + SHIFT + ALT + G", "WhatsApp", webapp("https://web.whatsapp.com/"))
  bind("SUPER + SHIFT + CTRL + G", "Google Messages", webapp("https://messages.google.com/web/conversations"))
  bind("SUPER + SHIFT + P", "Google Fotos", webapp("https://photos.google.com/"))
  bind("SUPER + SHIFT + S", "Google Maps", webapp("https://maps.google.com/"))
  bind("SUPER + SHIFT + X", "X", webapp("https://x.com/"))
  bind("SUPER + SHIFT + ALT + X", "X Beitrag schreiben", webapp("https://x.com/compose/post"))
end)


-- ============================================================================
--  Zwischenablage (Strg+Einfg / Umschalt+Einfg funktionieren auch im Terminal)
-- ============================================================================
section("Zwischenablage", function()
  bind("SUPER + A", "Alles auswählen", send_shortcut("CTRL", "A"))
  bind("SUPER + C", "Kopieren", send_shortcut("CTRL", "Insert"))
  bind("SUPER + V", "Einfügen", send_shortcut("SHIFT", "Insert"))
  bind("SUPER + X", "Ausschneiden", send_shortcut("CTRL", "X"))
  bind("SUPER + CTRL + V", "Zwischenablage-Verlauf", cmd.clipboard)
end)


-- ============================================================================
--  Fenster
-- ============================================================================
section("Fenster", function()
  bind("SUPER + W", "Fenster schließen", hl.dsp.window.close())
  bind("SUPER + Q", "Fenster schließen", hl.dsp.window.close())
  bind("CTRL + ALT + DELETE", "Alle Fenster schließen", act.close_all)

  bind("SUPER + J", "Teilung umschalten", hl.dsp.layout("togglesplit"))
  bind("SUPER + P", "Pseudo-Kachel", hl.dsp.window.pseudo())
  bind("SUPER + T", "Schwebend/gekachelt umschalten", hl.dsp.window.float({ action = "toggle" }))
  bind("SUPER + F", "Vollbild", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
  bind("SUPER + CTRL + F", "Gekacheltes Vollbild", cmd.tiledFullscreen)
  bind("SUPER + ALT + F", "Volle Breite", hl.dsp.window.fullscreen({ mode = "maximized" }))
  bind("SUPER + O", "Fenster herauslösen (schwebend + angepinnt)", act.pop)
  bind("SUPER + L", "Layout wechseln", cycle_layout(1))
  bind("SUPER + ALT + L", "Layout zurück wechseln", cycle_layout(-1))
  bind("XF86Display", "Layout wechseln", cycle_layout(1))

  bind("SUPER + LEFT", "Fokus links", hl.dsp.focus({ direction = "l" }))
  bind("SUPER + RIGHT", "Fokus rechts", hl.dsp.focus({ direction = "r" }))
  bind("SUPER + UP", "Fokus oben", hl.dsp.focus({ direction = "u" }))
  bind("SUPER + DOWN", "Fokus unten", hl.dsp.focus({ direction = "d" }))

  bind("SUPER + SHIFT + LEFT", "Fenster nach links tauschen", hl.dsp.window.swap({ direction = "l" }))
  bind("SUPER + SHIFT + RIGHT", "Fenster nach rechts tauschen", hl.dsp.window.swap({ direction = "r" }))
  bind("SUPER + SHIFT + UP", "Fenster nach oben tauschen", hl.dsp.window.swap({ direction = "u" }))
  bind("SUPER + SHIFT + DOWN", "Fenster nach unten tauschen", hl.dsp.window.swap({ direction = "d" }))

  bind("ALT + SHIFT + TAB", "Aktives Fenster nach hinten", hl.dsp.window.alter_zorder({ mode = "bottom" }))
  bind("ALT + TAB", "Nächstes Fenster", hl.dsp.window.cycle_next())
  bind("ALT + SHIFT + TAB", "Vorheriges Fenster", hl.dsp.window.cycle_next({ next = false }))
  bind("ALT + TAB", "Aktives Fenster nach vorne", hl.dsp.window.bring_to_top())

  -- Größe ändern mit - und = (Tastencodes, unabhängig vom Layout)
  local function resize(x, y)
    return hl.dsp.window.resize({ x = x, y = y, relative = true })
  end
  bind("SUPER + code:20", "Fenster links verbreitern", resize(-100, 0))
  bind("SUPER + code:21", "Fenster links verschmälern", resize(100, 0))
  bind("SUPER + SHIFT + code:20", "Fenster oben verkleinern", resize(0, -100))
  bind("SUPER + SHIFT + code:21", "Fenster unten vergrößern", resize(0, 100))
  bind("SUPER + ALT + code:20", "Fenster links etwas verbreitern", resize(-25, 0))
  bind("SUPER + ALT + code:21", "Fenster links etwas verschmälern", resize(25, 0))
  bind("SUPER + SHIFT + ALT + code:20", "Fenster oben etwas verkleinern", resize(0, -25))
  bind("SUPER + SHIFT + ALT + code:21", "Fenster unten etwas vergrößern", resize(0, 25))
  bind("SUPER + CTRL + code:20", "Fenster links stark verbreitern", resize(-300, 0))
  bind("SUPER + CTRL + code:21", "Fenster links stark verschmälern", resize(300, 0))
  bind("SUPER + CTRL + SHIFT + code:20", "Fenster oben stark verkleinern", resize(0, -300))
  bind("SUPER + CTRL + SHIFT + code:21", "Fenster unten stark vergrößern", resize(0, 300))

  bind("SUPER + mouse:272", "Fenster verschieben", hl.dsp.window.drag(), { mouse = true })
  bind("SUPER + mouse:273", "Fenstergröße ändern", hl.dsp.window.resize(), { mouse = true })

  bind("SUPER + BACKSPACE", "Transparenz des Fensters umschalten", act.toggle_opaque)
  bind("SUPER + SHIFT + BACKSPACE", "Fensterabstände umschalten", act.toggle_gaps)
end)


-- ============================================================================
--  Gruppen (Tabs)
-- ============================================================================
section("Gruppen", function()
  bind("SUPER + G", "Gruppe umschalten", hl.dsp.group.toggle())
  bind("SUPER + ALT + G", "Fenster aus Gruppe lösen", hl.dsp.window.move({ out_of_group = true }))
  bind("SUPER + ALT + LEFT", "In Gruppe links verschieben", hl.dsp.window.move({ into_group = "l" }))
  bind("SUPER + ALT + RIGHT", "In Gruppe rechts verschieben", hl.dsp.window.move({ into_group = "r" }))
  bind("SUPER + ALT + UP", "In Gruppe oben verschieben", hl.dsp.window.move({ into_group = "u" }))
  bind("SUPER + ALT + DOWN", "In Gruppe unten verschieben", hl.dsp.window.move({ into_group = "d" }))
  bind("SUPER + ALT + TAB", "Nächstes Fenster der Gruppe", hl.dsp.group.next())
  bind("SUPER + ALT + SHIFT + TAB", "Vorheriges Fenster der Gruppe", hl.dsp.group.prev())
  bind("SUPER + CTRL + LEFT", "Gruppenfokus links", hl.dsp.group.prev())
  bind("SUPER + CTRL + RIGHT", "Gruppenfokus rechts", hl.dsp.group.next())
  bind("SUPER + ALT + mouse_down", "Nächstes Fenster der Gruppe", hl.dsp.group.next())
  bind("SUPER + ALT + mouse_up", "Vorheriges Fenster der Gruppe", hl.dsp.group.prev())
  for index = 1, 5 do
    bind("SUPER + ALT + code:" .. (index + 9), "Gruppenfenster " .. index, hl.dsp.group.active({ index = index }))
  end
end)


-- ============================================================================
--  Arbeitsflächen (Zahlenreihe über Tastencodes, unabhängig vom Layout)
-- ============================================================================
section("Arbeitsflächen", function()
  for n = 1, 10 do
    local key = "code:" .. (n + 9)
    local ws = tostring(n)
    bind("SUPER + " .. key, "Arbeitsfläche " .. n, hl.dsp.focus({ workspace = ws }))
    bind("SUPER + SHIFT + " .. key, "Fenster auf Arbeitsfläche " .. n, hl.dsp.window.move({ workspace = ws, follow = true }))
    bind("SUPER + SHIFT + ALT + " .. key, "Fenster still auf Arbeitsfläche " .. n, hl.dsp.window.move({ workspace = ws, follow = false }))
  end

  bind("SUPER + TAB", "Nächste Arbeitsfläche", hl.dsp.focus({ workspace = "m+1" }))
  bind("SUPER + SHIFT + TAB", "Vorherige Arbeitsfläche", hl.dsp.focus({ workspace = "m-1" }))
  bind("SUPER + CTRL + TAB", "Zuletzt benutzte Arbeitsfläche", hl.dsp.focus({ workspace = "previous_per_monitor" }))
  bind("SUPER + mouse_down", "Arbeitsfläche vor", hl.dsp.focus({ workspace = "m+1" }))
  bind("SUPER + mouse_up", "Arbeitsfläche zurück", hl.dsp.focus({ workspace = "m-1" }))

  bind("SUPER + S", "Scratchpad umschalten", hl.dsp.workspace.toggle_special("scratchpad"))
  bind("SUPER + ALT + S", "Fenster ins Scratchpad", hl.dsp.window.move({ workspace = "special:scratchpad", follow = false }))
  bind("SUPER + code:49", "Quake-Konsole umschalten", act.qconsole)
  bind("SUPER + SHIFT + code:49", "Fenster in die Quake-Konsole", hl.dsp.window.move({ workspace = "special:qconsole", follow = false }))
  bind("SUPER + M", "Fenster minimieren", hl.dsp.window.move({ workspace = "special:minimized", follow = false }))
end)


-- ============================================================================
--  Monitore
-- ============================================================================
section("Monitore", function()
  bind("CTRL + ALT + TAB", "Nächster Monitor", hl.dsp.focus({ monitor = "+1" }))
  bind("CTRL + ALT + SHIFT + TAB", "Vorheriger Monitor", hl.dsp.focus({ monitor = "-1" }))
  for dir, name in pairs({ l = "linken", r = "rechten", u = "oberen", d = "unteren" }) do
    local key = ({ l = "LEFT", r = "RIGHT", u = "UP", d = "DOWN" })[dir]
    bind("SUPER + SHIFT + ALT + " .. key, "Arbeitsfläche auf " .. name .. " Monitor", workspace_to_monitor(dir))
    bind("SUPER + SHIFT + CTRL + " .. key, "Fenster auf " .. name .. " Monitor", window_to_monitor(dir))
  end
  bind("SUPER + CTRL + Delete", "Laptop-Bildschirm umschalten", act.toggle_laptop_display)
end)


-- ============================================================================
--  Menüs und System
-- ============================================================================
section("System", function()
  bind("SUPER + SPACE", "App-Starter", apps.launcher)
  bind("SUPER + ALT + SPACE", "App-Starter", apps.launcher)
  bind("SUPER + ESCAPE", "Systemmenü", cmd.power)
  bind("XF86PowerOff", "Systemmenü", cmd.power, { locked = true })
  bind("SUPER + K", "Tastenkürzel anzeigen", cmd.keybindings)
  bind("SUPER + CTRL + E", "Emojis", apps.emojiPicker)
  bind("SUPER + SHIFT + SPACE", "Leiste ein/aus (Waybar)", "pkill -SIGUSR1 waybar")
  bind("SUPER + CTRL + I", "Sperre bei Inaktivität umschalten", cmd.idle)
  bind("SUPER + CTRL + L", "Bildschirm sperren", "pidof hyprlock || hyprlock")

  bind("SUPER + CTRL + A", "Audio", apps.audioControl)
  bind("SUPER + CTRL + B", "Bluetooth", apps.bluetoothControl)
  bind("SUPER + CTRL + N", "Netzwerk", apps.networkControl)

  bind("SUPER + CTRL + ALT + T", "Uhrzeit anzeigen", [[notify-send "$(date +'%H:%M')" "$(date +'%A, %d. %B %Y')"]])
  bind("SUPER + CTRL + ALT + B", "Akkustand anzeigen", [[notify-send "Akku" "$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -n1 || echo '?') %"]])
  bind("SUPER + CTRL + ALT + W", "Wetter anzeigen", [[notify-send "Wetter" "$(curl -fsS 'https://wttr.in/?format=3' || echo 'nicht verfügbar')"]])

  bind("SUPER + CTRL + Z", "Hineinzoomen", act.zoom_in)
  bind("SUPER + CTRL + ALT + Z", "Zoom zurücksetzen", act.zoom_reset)
end)


-- ============================================================================
--  Benachrichtigungen (mako oder swaync)
-- ============================================================================
section("Benachrichtigungen", function()
  bind("SUPER + comma", "Letzte Benachrichtigung schließen", cmd.notifyDismiss)
  bind("SUPER + ALT + comma", "Letzte Benachrichtigung schließen", cmd.notifyDismiss)
  bind("SUPER + SHIFT + comma", "Alle Benachrichtigungen schließen", "makoctl dismiss --all 2>/dev/null || swaync-client --close-all")
  bind("SUPER + CTRL + comma", "Aktion der Benachrichtigung ausführen", "makoctl invoke 2>/dev/null || swaync-client --open-panel")
  bind("SUPER + SHIFT + ALT + comma", "Benachrichtigungsverlauf", "makoctl restore 2>/dev/null || swaync-client --toggle-panel")
  bind("SUPER + CTRL + ALT + comma", "Nicht stören umschalten", "makoctl mode -t do-not-disturb 2>/dev/null || swaync-client --toggle-dnd")
end)


-- ============================================================================
--  Bildschirmfoto, Aufnahme, Farbwähler
-- ============================================================================
section("Aufnahme", function()
  bind("PRINT", "Bildschirmfoto", cmd.screenshot)
  bind("SUPER + CTRL + ALT + C", "Bildschirmfoto", cmd.screenshot)
  bind("ALT + PRINT", "Bildschirmaufnahme (mit Ton) starten/stoppen", cmd.screenrecordAudio)
  bind("SUPER + SHIFT + CTRL + ALT + C", "Bildschirmaufnahme (ohne Ton) starten/stoppen", cmd.screenrecord)
  bind("SUPER + PRINT", "Farbwähler", "pkill hyprpicker || hyprpicker -a")
  bind("SUPER + CTRL + PRINT", "Text aus Bildschirmfoto erkennen (OCR)", cmd.ocr)
end)


-- ============================================================================
--  Lautstärke, Helligkeit, Medien (funktionieren auch im Sperrbildschirm)
-- ============================================================================
section("Medien", function()
  local lr = { locked = true, repeating = true }
  local l = { locked = true }

  bind("XF86AudioRaiseVolume", "Lauter", cmd.volumeUp, lr)
  bind("XF86AudioLowerVolume", "Leiser", cmd.volumeDown, lr)
  bind("XF86AudioMute", "Stumm", "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle", l)
  bind("XF86AudioMicMute", "Mikrofon stumm", "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle", l)
  bind("ALT + XF86AudioRaiseVolume", "Lauter (fein)", "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 1%+", lr)
  bind("ALT + XF86AudioLowerVolume", "Leiser (fein)", "wpctl set-volume @DEFAULT_AUDIO_SINK@ 1%-", lr)

  bind("XF86MonBrightnessUp", "Heller", "brightnessctl -e4 -n2 set 5%+", lr)
  bind("XF86MonBrightnessDown", "Dunkler", "brightnessctl -e4 -n2 set 5%-", lr)
  bind("SHIFT + XF86MonBrightnessUp", "Maximale Helligkeit", "brightnessctl set 100%", lr)
  bind("SHIFT + XF86MonBrightnessDown", "Minimale Helligkeit", "brightnessctl -n2 set 1%", lr)
  bind("ALT + XF86MonBrightnessUp", "Heller (fein)", "brightnessctl -n2 set 1%+", lr)
  bind("ALT + XF86MonBrightnessDown", "Dunkler (fein)", "brightnessctl -n2 set 1%-", lr)

  bind("XF86KbdBrightnessUp", "Tastaturbeleuchtung heller", cmd.kbdUp, lr)
  bind("XF86KbdBrightnessDown", "Tastaturbeleuchtung dunkler", cmd.kbdDown, lr)
  bind("CTRL + XF86MonBrightnessUp", "Tastaturbeleuchtung heller", cmd.kbdUp, lr)
  bind("CTRL + XF86MonBrightnessDown", "Tastaturbeleuchtung dunkler", cmd.kbdDown, lr)

  bind("XF86AudioNext", "Nächster Titel", "playerctl next", l)
  bind("ALT + XF86AudioPlay", "Nächster Titel", "playerctl next", l)
  bind("XF86AudioPause", "Pause", "playerctl play-pause", l)
  bind("XF86AudioPlay", "Abspielen", "playerctl play-pause", l)
  bind("XF86AudioPrev", "Vorheriger Titel", "playerctl previous", l)
  bind("ALT + SHIFT + XF86AudioPlay", "Vorheriger Titel", "playerctl previous", l)
  bind("SHIFT + XF86AudioPlay", "Mediaplayer wechseln", "playerctld shift", l)
  bind("SHIFT + XF86AudioPause", "Mediaplayer wechseln", "playerctld shift", l)
  bind("XF86Eject", "Medium auswerfen", "eject", l)
end)


-- ----------------------------------------------------------------------------
--  Fehler melden statt still zu schlucken
-- ----------------------------------------------------------------------------
if #errors > 0 then
  local message = table.concat(errors, "\n")
  io.stderr:write("omarchy-keybindings: " .. #errors .. " Fehler\n" .. message .. "\n")
  pcall(hl.exec_cmd, "notify-send -u critical 'omarchy-keybindings: " .. #errors .. " Fehler' " .. sh_quote(message))
end
