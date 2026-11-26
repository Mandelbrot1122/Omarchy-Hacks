# Omarchy-Keybindings für normales Hyprland

Alle Tastenkürzel von [Omarchy](https://github.com/basecamp/omarchy) in **einer Datei** für jedes
normale Hyprland, in zwei Varianten:

- [`omarchy-keybindings.lua`](omarchy-keybindings.lua) für Hyprland mit **`hyprland.lua`**
- [`omarchy-keybindings.conf`](omarchy-keybindings.conf) für das klassische **`hyprland.conf`**

Beide Varianten sind
ohne Omarchy selbst. Statt der `omarchy-*`-Skripte nutzt sie Standard-Tools
(wpctl, brightnessctl, playerctl, grim/slurp, hyprlock, cliphist, …).

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/mandelbrot1122/omarchy-hacks/HEAD/install.sh | bash
```

Oder per Git:

```bash
git clone https://github.com/mandelbrot1122/omarchy-hacks.git
cd omarchy-hacks
./install.sh
```

Das Skript

1. erkennt, ob du `hyprland.lua` oder `hyprland.conf` nutzt, und kopiert die passende Datei
   nach `~/.config/hypr/`,
2. erkennt deine installierten Programme (Terminal, Browser, Dateimanager, Launcher, …)
   und trägt sie oben in der Datei ein,
3. bindet sie am Ende deiner Konfiguration ein, mit Sicherung als `.bak`:
   - Lua: `dofile("/home/…/.config/hypr/omarchy-keybindings.lua")`
   - conf: `source = /home/…/.config/hypr/omarchy-keybindings.conf`
4. richtet die **Leiste oben** ein: Waybar im Stil von Omarchy (Arbeitsflächen, Uhr, Wetter,
   Tray, Bluetooth, Netzwerk, Lautstärke, CPU, Akku). Eine vorhandene Waybar-Konfiguration
   wird vorher als `~/.config/waybar.bak-…` gesichert,
5. zeigt fehlende Abhängigkeiten an und lädt Hyprland neu.

| Option | Wirkung |
|---|---|
| `--install-deps` | fehlende Pakete mit `pacman` installieren (Arch) |
| `--no-detect` | Programme nicht erkennen, Standardwerte behalten |
| `--no-waybar` | keine Waybar-Leiste einrichten |
| `--uninstall` | source-Zeile entfernen, Datei als `.bak` zur Seite legen |

Optionen beim Einzeiler: `curl -fsSL …/install.sh | bash -s -- --install-deps`

### Abhängigkeiten

Arch:

```bash
sudo pacman -S --needed jq wireplumber brightnessctl playerctl grim slurp wl-clipboard \
  cliphist hyprpicker hyprlock hypridle wf-recorder tesseract tesseract-data-deu libnotify wofi \
  waybar ttf-jetbrains-mono-nerd
```

Dazu optional ein Terminal, Browser, Dateimanager usw. nach Wahl. Das Skript erkennt u. a.
kitty, alacritty, ghostty, foot · firefox, chromium, brave · nautilus, thunar, dolphin ·
walker, fuzzel, rofi, wofi · wiremix/pavucontrol · bluetui/blueman · impala/nm-connection-editor.
Benachrichtigungen funktionieren mit **mako** oder **swaync**, die Leiste mit **waybar**.

## Anpassen

- **Programme:** Oben in der installierten Datei stehen `terminal`, `browser`, `launcher` usw.
  (Lua: Tabelle `apps`, conf: Variablen `$terminal`, …). Dort ändern.
- **Eigene Bindings / Bindings überschreiben:** **nach** der Einbindungszeile, z. B.
  ```lua
  -- hyprland.lua
  hl.unbind("SUPER + Q")
  hl.bind("SUPER + Q", hl.dsp.exec_cmd("kitty"), { description = "Terminal" })
  ```
  ```ini
  # hyprland.conf
  unbind = SUPER, Q
  bind = SUPER, Q, exec, kitty
  ```
- Beide Varianten entfernen vorher definierte Bindings auf den Tasten, die sie selbst belegen
  (z. B. `SUPER + M = exit` aus der Hyprland-Standardconfig). In der conf-Variante steht dafür
  ein `unbind`-Block, den `tools/update-unbinds.sh` nach Änderungen neu erzeugt.
- Lua-Variante: Schlägt ein Abschnitt fehl (z. B. nach einer API-Änderung in Hyprland), laufen
  die anderen weiter, und eine Benachrichtigung nennt den Fehler.
- Alle aktiven Tastenkürzel anzeigen: **`SUPER + K`**.

## Unterschiede zu Omarchy

- **Menüs:** `SUPER + SPACE` öffnet den App-Starter (nochmal drücken oder Escape schließt ihn), `SUPER + ESCAPE` ein einfaches Systemmenü
  (Sperren, Abmelden, Bereitschaft, Neustart, Herunterfahren).
- **Arbeitsflächen** sind global (Hyprland-Standard), nicht pro Monitor 1–10 wie in Omarchy.
- **`SUPER + L`** wechselt das Layout global zwischen *dwindle* und *master*.
- **Nicht übernommen**, weil sie Omarchy-eigene Programme oder Zustände brauchen: Theme-,
  Hintergrund-, Hardware-, Toggle-, Capture- und Teilen-Menü, Bar-Panels (`SUPER + CTRL + 1–9`),
  Diktierfunktion, Erinnerungen, Transcode, Webcam-Overlay, Fensterbreite speichern
  (`SUPER + Home`), Monitor-Skalierung (`SUPER + /`), Herdr, Omawrite, cliamp, Tastatur-
  beleuchtung durchschalten, Touchpad-Tasten, Audioausgang wechseln, Laptop-Spiegelung,
  Deckel-Schalter (übernimmt systemd-logind), JIS- und Eingabemethoden-Sonderbelegungen.

Stand: Omarchy-Bindings vom 25.11.2026 (`basecamp/omarchy@3b1a913`).

## Alle Tastenkürzel

### Programme

| Tasten | Funktion |
|---|---|
| `SUPER + RETURN` | Terminal |
| `SUPER + SHIFT + RETURN` | Browser |
| `SUPER + SHIFT + B` | Browser |
| `SUPER + SHIFT + ALT + B` | Browser (privat) |
| `SUPER + SHIFT + F` | Dateimanager |
| `SUPER + ALT + SHIFT + F` | Dateimanager im aktuellen Ordner |
| `SUPER + SHIFT + N` | Editor |
| `SUPER + ALT + RETURN` | Tmux |
| `SUPER + SHIFT + Q` | Taschenrechner |
| `XF86Calculator` | Taschenrechner |
| `SUPER + SHIFT + D` | Docker (lazydocker) |
| `SUPER + SHIFT + O` | Obsidian |
| `SUPER + SHIFT + slash` | Passwörter (1Password) |
| `SUPER + SHIFT + T` | Systemmonitor (btop) |
| `SUPER + SHIFT + M` | Musik (Spotify) |
| `SUPER + SHIFT + G` | Signal |
| `SUPER + SHIFT + A` | ChatGPT |
| `SUPER + SHIFT + ALT + A` | Grok |
| `SUPER + SHIFT + C` | Kalender (HEY) |
| `SUPER + SHIFT + E` | E-Mail (HEY) |
| `SUPER + SHIFT + ALT + E` | Neue E-Mail (HEY) |
| `SUPER + SHIFT + Y` | YouTube |
| `SUPER + SHIFT + ALT + G` | WhatsApp |
| `SUPER + SHIFT + CTRL + G` | Google Messages |
| `SUPER + SHIFT + P` | Google Fotos |
| `SUPER + SHIFT + S` | Google Maps |
| `SUPER + SHIFT + X` | X |
| `SUPER + SHIFT + ALT + X` | X Beitrag schreiben |

### Zwischenablage (funktioniert auch im Terminal)

| Tasten | Funktion |
|---|---|
| `SUPER + A` | Alles auswählen |
| `SUPER + C` | Kopieren |
| `SUPER + V` | Einfügen |
| `SUPER + X` | Ausschneiden |
| `SUPER + CTRL + V` | Zwischenablage-Verlauf |

### Fenster

| Tasten | Funktion |
|---|---|
| `SUPER + W` | Fenster schließen |
| `SUPER + Q` | Fenster schließen |
| `CTRL + ALT + DELETE` | Alle Fenster schließen |
| `SUPER + J` | Teilung umschalten |
| `SUPER + P` | Pseudo-Kachel |
| `SUPER + T` | Schwebend/gekachelt umschalten |
| `SUPER + F` | Vollbild |
| `SUPER + CTRL + F` | Gekacheltes Vollbild |
| `SUPER + ALT + F` | Volle Breite |
| `SUPER + O` | Fenster herauslösen (schwebend + angepinnt) |
| `SUPER + L` | Layout wechseln (dwindle/master) |
| `SUPER + ALT + L` | Layout wechseln (dwindle/master) |
| `XF86Display` | Layout wechseln (dwindle/master) |
| `SUPER + LEFT` | Fokus links |
| `SUPER + RIGHT` | Fokus rechts |
| `SUPER + UP` | Fokus oben |
| `SUPER + DOWN` | Fokus unten |
| `SUPER + SHIFT + LEFT` | Fenster nach links tauschen |
| `SUPER + SHIFT + RIGHT` | Fenster nach rechts tauschen |
| `SUPER + SHIFT + UP` | Fenster nach oben tauschen |
| `SUPER + SHIFT + DOWN` | Fenster nach unten tauschen |
| `ALT + SHIFT + TAB` | Aktives Fenster nach hinten |
| `ALT + TAB` | Nächstes Fenster |
| `ALT + SHIFT + TAB` | Vorheriges Fenster |
| `ALT + TAB` | Aktives Fenster nach vorne |
| `SUPER + -` | Fenster links verbreitern |
| `SUPER + =` | Fenster links verschmälern |
| `SUPER + SHIFT + -` | Fenster oben verkleinern |
| `SUPER + SHIFT + =` | Fenster unten vergrößern |
| `SUPER + ALT + -` | Fenster links etwas verbreitern |
| `SUPER + ALT + =` | Fenster links etwas verschmälern |
| `SUPER + SHIFT + ALT + -` | Fenster oben etwas verkleinern |
| `SUPER + SHIFT + ALT + =` | Fenster unten etwas vergrößern |
| `SUPER + CTRL + -` | Fenster links stark verbreitern |
| `SUPER + CTRL + =` | Fenster links stark verschmälern |
| `SUPER + CTRL + SHIFT + -` | Fenster oben stark verkleinern |
| `SUPER + CTRL + SHIFT + =` | Fenster unten stark vergrößern |
| `SUPER + Linke Maustaste` | Fenster verschieben |
| `SUPER + Rechte Maustaste` | Fenstergröße ändern |
| `SUPER + BACKSPACE` | Transparenz des Fensters umschalten |
| `SUPER + SHIFT + BACKSPACE` | Fensterabstände umschalten |

### Gruppen (Tabs)

| Tasten | Funktion |
|---|---|
| `SUPER + G` | Gruppe umschalten |
| `SUPER + ALT + G` | Fenster aus Gruppe lösen |
| `SUPER + ALT + LEFT` | In Gruppe links verschieben |
| `SUPER + ALT + RIGHT` | In Gruppe rechts verschieben |
| `SUPER + ALT + UP` | In Gruppe oben verschieben |
| `SUPER + ALT + DOWN` | In Gruppe unten verschieben |
| `SUPER + ALT + TAB` | Nächstes Fenster der Gruppe |
| `SUPER + ALT + SHIFT + TAB` | Vorheriges Fenster der Gruppe |
| `SUPER + CTRL + LEFT` | Gruppenfokus links |
| `SUPER + CTRL + RIGHT` | Gruppenfokus rechts |
| `SUPER + ALT + Mausrad runter` | Nächstes Fenster der Gruppe |
| `SUPER + ALT + Mausrad hoch` | Vorheriges Fenster der Gruppe |
| `SUPER + ALT + 1` | Gruppenfenster 1 |
| `SUPER + ALT + 2` | Gruppenfenster 2 |
| `SUPER + ALT + 3` | Gruppenfenster 3 |
| `SUPER + ALT + 4` | Gruppenfenster 4 |
| `SUPER + ALT + 5` | Gruppenfenster 5 |

### Arbeitsflächen (Zahlenreihe über Tastencodes, unabhängig vom Layout)

| Tasten | Funktion |
|---|---|
| `SUPER + 1` | Arbeitsfläche 1 |
| `SUPER + 2` | Arbeitsfläche 2 |
| `SUPER + 3` | Arbeitsfläche 3 |
| `SUPER + 4` | Arbeitsfläche 4 |
| `SUPER + 5` | Arbeitsfläche 5 |
| `SUPER + 6` | Arbeitsfläche 6 |
| `SUPER + 7` | Arbeitsfläche 7 |
| `SUPER + 8` | Arbeitsfläche 8 |
| `SUPER + 9` | Arbeitsfläche 9 |
| `SUPER + 0` | Arbeitsfläche 10 |
| `SUPER + SHIFT + 1` | Fenster auf Arbeitsfläche 1 |
| `SUPER + SHIFT + 2` | Fenster auf Arbeitsfläche 2 |
| `SUPER + SHIFT + 3` | Fenster auf Arbeitsfläche 3 |
| `SUPER + SHIFT + 4` | Fenster auf Arbeitsfläche 4 |
| `SUPER + SHIFT + 5` | Fenster auf Arbeitsfläche 5 |
| `SUPER + SHIFT + 6` | Fenster auf Arbeitsfläche 6 |
| `SUPER + SHIFT + 7` | Fenster auf Arbeitsfläche 7 |
| `SUPER + SHIFT + 8` | Fenster auf Arbeitsfläche 8 |
| `SUPER + SHIFT + 9` | Fenster auf Arbeitsfläche 9 |
| `SUPER + SHIFT + 0` | Fenster auf Arbeitsfläche 10 |
| `SUPER + SHIFT + ALT + 1` | Fenster still auf Arbeitsfläche 1 |
| `SUPER + SHIFT + ALT + 2` | Fenster still auf Arbeitsfläche 2 |
| `SUPER + SHIFT + ALT + 3` | Fenster still auf Arbeitsfläche 3 |
| `SUPER + SHIFT + ALT + 4` | Fenster still auf Arbeitsfläche 4 |
| `SUPER + SHIFT + ALT + 5` | Fenster still auf Arbeitsfläche 5 |
| `SUPER + SHIFT + ALT + 6` | Fenster still auf Arbeitsfläche 6 |
| `SUPER + SHIFT + ALT + 7` | Fenster still auf Arbeitsfläche 7 |
| `SUPER + SHIFT + ALT + 8` | Fenster still auf Arbeitsfläche 8 |
| `SUPER + SHIFT + ALT + 9` | Fenster still auf Arbeitsfläche 9 |
| `SUPER + SHIFT + ALT + 0` | Fenster still auf Arbeitsfläche 10 |
| `SUPER + TAB` | Nächste Arbeitsfläche |
| `SUPER + SHIFT + TAB` | Vorherige Arbeitsfläche |
| `SUPER + CTRL + TAB` | Zuletzt benutzte Arbeitsfläche |
| `SUPER + Mausrad runter` | Arbeitsfläche vor |
| `SUPER + Mausrad hoch` | Arbeitsfläche zurück |
| `SUPER + S` | Scratchpad umschalten |
| `SUPER + ALT + S` | Fenster ins Scratchpad |
| `SUPER + ^ (Taste links von 1)` | Quake-Konsole umschalten |
| `SUPER + SHIFT + ^ (Taste links von 1)` | Fenster in die Quake-Konsole |
| `SUPER + M` | Fenster minimieren |

### Monitore

| Tasten | Funktion |
|---|---|
| `CTRL + ALT + TAB` | Nächster Monitor |
| `CTRL + ALT + SHIFT + TAB` | Vorheriger Monitor |
| `SUPER + SHIFT + ALT + LEFT` | Arbeitsfläche auf linken Monitor |
| `SUPER + SHIFT + ALT + RIGHT` | Arbeitsfläche auf rechten Monitor |
| `SUPER + SHIFT + ALT + UP` | Arbeitsfläche auf oberen Monitor |
| `SUPER + SHIFT + ALT + DOWN` | Arbeitsfläche auf unteren Monitor |
| `SUPER + SHIFT + CTRL + LEFT` | Fenster auf linken Monitor |
| `SUPER + SHIFT + CTRL + RIGHT` | Fenster auf rechten Monitor |
| `SUPER + SHIFT + CTRL + UP` | Fenster auf oberen Monitor |
| `SUPER + SHIFT + CTRL + DOWN` | Fenster auf unteren Monitor |
| `SUPER + CTRL + DELETE` | Laptop-Bildschirm umschalten |

### Menüs und System

| Tasten | Funktion |
|---|---|
| `SUPER + SPACE` | App-Starter |
| `SUPER + ALT + SPACE` | App-Starter |
| `SUPER + ESCAPE` | Systemmenü |
| `XF86PowerOff` | Systemmenü |
| `SUPER + K` | Tastenkürzel anzeigen |
| `SUPER + CTRL + E` | Emojis |
| `SUPER + SHIFT + SPACE` | Leiste ein/aus (Waybar) |
| `SUPER + CTRL + I` | Sperre bei Inaktivität umschalten |
| `SUPER + CTRL + L` | Bildschirm sperren |
| `SUPER + CTRL + A` | Audio |
| `SUPER + CTRL + B` | Bluetooth |
| `SUPER + CTRL + N` | Netzwerk |
| `SUPER + CTRL + ALT + T` | Uhrzeit anzeigen |
| `SUPER + CTRL + ALT + B` | Akkustand anzeigen |
| `SUPER + CTRL + ALT + W` | Wetter anzeigen |
| `SUPER + CTRL + Z` | Hineinzoomen |
| `SUPER + CTRL + ALT + Z` | Zoom zurücksetzen |

### Benachrichtigungen (mako oder swaync)

| Tasten | Funktion |
|---|---|
| `SUPER + comma` | Letzte Benachrichtigung schließen |
| `SUPER + ALT + comma` | Letzte Benachrichtigung schließen |
| `SUPER + SHIFT + comma` | Alle Benachrichtigungen schließen |
| `SUPER + CTRL + comma` | Aktion der Benachrichtigung ausführen |
| `SUPER + SHIFT + ALT + comma` | Benachrichtigungsverlauf |
| `SUPER + CTRL + ALT + comma` | Nicht stören umschalten |

### Bildschirmfoto, Aufnahme, Farbwähler

| Tasten | Funktion |
|---|---|
| `PRINT` | Bildschirmfoto |
| `SUPER + CTRL + ALT + C` | Bildschirmfoto |
| `ALT + PRINT` | Bildschirmaufnahme (mit Ton) starten/stoppen |
| `SUPER + SHIFT + CTRL + ALT + C` | Bildschirmaufnahme (ohne Ton) starten/stoppen |
| `SUPER + PRINT` | Farbwähler |
| `SUPER + CTRL + PRINT` | Text aus Bildschirmfoto erkennen (OCR) |

### Lautstärke, Helligkeit, Medien (funktionieren auch im Sperrbildschirm)

| Tasten | Funktion |
|---|---|
| `XF86AudioRaiseVolume` | Lauter |
| `XF86AudioLowerVolume` | Leiser |
| `XF86AudioMute` | Stumm |
| `XF86AudioMicMute` | Mikrofon stumm |
| `ALT + XF86AudioRaiseVolume` | Lauter (fein) |
| `ALT + XF86AudioLowerVolume` | Leiser (fein) |
| `XF86MonBrightnessUp` | Heller |
| `XF86MonBrightnessDown` | Dunkler |
| `SHIFT + XF86MonBrightnessUp` | Maximale Helligkeit |
| `SHIFT + XF86MonBrightnessDown` | Minimale Helligkeit |
| `ALT + XF86MonBrightnessUp` | Heller (fein) |
| `ALT + XF86MonBrightnessDown` | Dunkler (fein) |
| `XF86KbdBrightnessUp` | Tastaturbeleuchtung heller |
| `XF86KbdBrightnessDown` | Tastaturbeleuchtung dunkler |
| `CTRL + XF86MonBrightnessUp` | Tastaturbeleuchtung heller |
| `CTRL + XF86MonBrightnessDown` | Tastaturbeleuchtung dunkler |
| `XF86AudioNext` | Nächster Titel |
| `ALT + XF86AudioPlay` | Nächster Titel |
| `XF86AudioPause` | Pause |
| `XF86AudioPlay` | Abspielen |
| `XF86AudioPrev` | Vorheriger Titel |
| `ALT + SHIFT + XF86AudioPlay` | Vorheriger Titel |
| `SHIFT + XF86AudioPlay` | Mediaplayer wechseln |
| `SHIFT + XF86AudioPause` | Mediaplayer wechseln |
| `XF86Eject` | Medium auswerfen |
