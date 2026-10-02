# eww shell: minimal Gruvbox on AMOLED black

This eww config replaces waybar, rofi and swaync on niri. It has:

- a bar on every output
- an app launcher and an app drawer
- a clipboard panel
- a control centre that also holds notification history
- notification popups
- a calendar
- a power menu
- a volume/brightness OSD
- a full-screen wallpaper picker with a slideshow

## Keys (niri)

| Key | Surface |
|---|---|
| `Mod+D` | Launcher. Type, then `Enter` launches the top hit. `Tab` moves focus. Press `Mod+D` again to close. |
|  | The footer sorts the list: Recent (apps whose window you opened most recently, any way you opened them), Frequent, or A–Z. `Alt+Tab` / `Alt+Shift+Tab` cycles it (also in the drawer). The choice is remembered; while searching, relevance comes first and the sort breaks ties. |
| `Mod+A` | App drawer. You can also click the Arch logo on the bar; right-clicking it opens the launcher. |
| `Mod+C` / `Mod+Shift+C` | Clipboard history, all items / images only |
| `Mod+N` | Control centre and notifications. Clicking the status icons on the bar does the same. |
| `Mod+Shift+N` | Toggle Do Not Disturb |
| `Ctrl+Shift+P` | Power menu. Every action except Lock needs a second press within 4s. |
| `Mod+Shift+W` | Wallpaper picker. It is also in the launcher as "Wallpapers". |
| Volume, mic and brightness keys | `scripts/osd.sh`: makes the change and shows the OSD |

**Bar items, right side.**

- **Drives.** `󰋊` is root and `󰋜` is home. A USB stick or other removable drive appears while it is mounted: click it to open the drive in the file manager, right-click to unmount and power it off.
- **Wi-Fi and Bluetooth.** Each shows the connected network or device name. The icon is grey when the radio is off and in the accent when it is on. Clicking either opens the control centre directly on its page.
- **Volume.** Scroll to change it, right-click to mute. A red mic icon appears while the microphone is muted; click it to unmute.
- **Notifications.** Shows the unread count. Right-click toggles Do Not Disturb.

`Escape` or a click anywhere outside closes the open popup. eww widgets cannot see key presses, so `panel.sh` binds a plain `Escape` in niri only while a popup is open: it rewrites `~/.config/niri/eww-escape.kdl` (included from `config.kdl`) and niri reloads it. The rest of the time Escape goes to your apps as usual.

## Layout

```
eww.yuck            includes yuck/*
eww.scss            imports scss/*
yuck/vars.yuck      every defvar / deflisten / defpoll
yuck/<surface>.yuck one window per file; shared widgets in widgets.yuck
scss/_tokens.scss   palette, size knobs ($type-scale, $space-scale), easing curves
scss/_paint.scss    every colour declaration, as one mixin drawn per palette
scss/_themes.scss   generated wallpaper palettes (scripts/theme.py scss)
scripts/            feeders that print one JSON line per change
launch.sh           starts the daemon and opens the bars and popups (spawned by niri)
```

**Data flow.** Every live value comes from a `deflisten` script that prints a JSON line whenever something changes. Nothing polls in a tight loop.

| Feeder | Source |
|---|---|
| `niri.py` | niri IPC event-stream socket |
| `audio.sh` | `pactl subscribe` |
| `net.sh` | `nmcli monitor` |
| `bt.py` | BlueZ D-Bus signals |
| `wall.py watch grid` / `watch status` | the wallpaper grid and its status, as two streams so status ticks never rebuild the grid |
| `wall.py watch theme` | the colour theme class for the current wallpaper |
| `disks.sh` | `lsblk` for root, home and removable drives, re-read on `udisksctl monitor` events and every 30s |
| `media.py` | Playerctl GObject API |
| `apps.py daemon` | desktop entries via Gio. Ranks by match quality plus frecency, and takes commands over a FIFO (`apps.py q TEXT`). |
| `niri.py ws` / `niri.py win` | workspaces and the focused window title, as two streams so title changes never rebuild the workspace buttons |
| `notifd.py watch` | streams state from the notification daemon (below) |

**Notifications.** `notifd.py` is a standalone `org.freedesktop.Notifications` server. D-Bus starts it on demand through `~/.local/share/dbus-1/services/org.freedesktop.Notifications.service`, which also stops swaync from being auto-activated.

- It is not part of eww, so `eww reload` never drops notifications.
- History and the DND state persist in `~/.cache/eww/notifd/history.json`.
- Widgets control it over D-Bus: `scripts/notif dismiss|hide|invoke|clear|dnd`.

**Popups.** `scripts/panel.sh toggle NAME` manages them:

- At most one popup is open at a time.
- It opens on the focused output over a click-away `backdrop` window.
- It animates content in through a revealer bound to the `reveal` var.
- It detaches itself, because eww kills handler commands after 200ms.

## Wallpapers

`scripts/wall.py` is a standalone daemon. `launch.sh` starts it at login, and it restores the last wallpaper through `awww` (it starts `awww-daemon` itself if needed). Because it runs outside eww, the slideshow keeps going when the picker is closed or eww reloads.

- **Library.** Everything under `~/Pictures/wallpapers` (change `LIBRARY` in `wall.py`). `.gif` files go to the Animated tab; jpg, png and webp go to Static. Favourites have their own tab.
- **Thumbnails.** These are cached in `~/.cache/eww/wall-thumbs`. Static ones are rounded PNGs made with Pillow. Animated ones are rounded GIFs made with ffmpeg: the first 4s at 10 fps, so a page of 18 still animates smoothly. eww cannot scale GIFs, so the thumbnail size in `wall.py` (`TW`, `TH`) must match the image size in `wallpapers.yuck`.
- **Picker.** Type to search. Click a tile to apply it, right-click to add or remove it from favourites, scroll the grid to change page. Random, Previous (history), Rescan and Open folder are in the footer.
- **Slideshow.** The footer controls it: on/off, every 1m to 1h, source (Static / Animated / All / Favourites), shuffle or in order, and the transition (Fade, Wipe, Grow, Wave, Shrink, Random).
- **State.** Saved in `~/.local/state/eww/wallpapers.json`.
- **From a terminal:** `wall.py next`, `wall.py random`, `wall.py back`, `wall.py slideshow toggle`.

A GIF takes a few seconds to apply while awww resizes every frame. The footer shows "applying…" meanwhile, and a newer pick cancels the one still in progress.

awww caches each GIF's resized frames in `~/.cache/awww/<version>/` and trusts that file on every later apply, so a cache cut off mid-write leaves the GIF frozen on its first frame. `wall.py` deletes the partial cache of an apply it cancels, and when awww reports "failed to load cached animation frames" it deletes that entry and applies the GIF once more.

## Writing your own widget

1. **Data.** Add a feeder script that prints compact JSON on change (`print(..., flush=True)`). Register it with `(deflisten foo :initial '{}' "scripts/foo.sh")` in `vars.yuck`.
2. **Widget.** Write it in a new `yuck/foo.yuck` and include it from `eww.yuck`:
   ```lisp
   (defwidget foo-chip []
     (label :class "item foo" :text "󰖐 ${foo.temp}°"))
   ```
   Put it on the bar by adding `(foo-chip)` to `bar` in `bar.yuck`, with a `(sep)` before it if it starts a new group.
3. **Style.** Reuse the tokens:
   ```scss
   .foo { padding: 0 sp(12px); color: $fg-dim; font-size: $fs-md; }
   ```
   Use `sp()` for spacing and `f()` for type so the size knobs apply to it.

Gotchas that cost a debug cycle each:

- eww adds each window's name as a CSS class to the window's root widget (here the theme wrapper box). A CSS class named like a window (`.bar`, `.osd`, `.calendar`) therefore also styles that wrapper and draws the card twice.
- Colour declarations belong in `scss/_paint.scss` only. One left in a layout file can lose to a themed rule that it used to beat.
- Never put widget-supplied text inside quotes in a handler: eww pastes `{}` and `${...}` into `sh -c` as raw text, so a `'` breaks the command and worse can run one. Typed text goes through a quoted here-doc (`scripts/x.py cmd - <<'EWW'` … `{}` … `EWW`); list rows pass an index and the script looks the value up.
- A `button` inside an `eventbox` with `:onclick` fires both handlers on one click (eww lets the release bubble). Keep buttons outside clickable eventboxes.
- A `for` rebuilds every child whenever its variable changes, even if the array is identical. Keep fast-changing fields in a separate variable from the list.

- `box` has `:space-evenly true` by default.
- `circular-progress` ignores CSS min-size. Give it `:width` and `:height`.
- `:limit-width` ellipsizes. Add `:lines N` to wrap instead.
- A `defvar` resets on every reload.
- Handlers have a 200ms timeout. Background anything slow with `setsid -f`.
- Use `?.` / `?:` on any JSON field that can be null.
- `{}` in a handler is substituted as raw text into the shell command, with no quoting.

## Theme

`scss/_tokens.scss` holds the whole theme:

- **Size.** `$type-scale` (1.5) scales text and icons; `$space-scale` (1.3) scales padding, gaps and component sizes. Change these two to resize everything. Window widths and image sizes in the yuck files are set to match by hand.
- **Colour.** Pure black bar, neutral grey popups (`$surface`, `$raised`, `$hover`), Gruvbox cream text in three strengths, and one accent (`$accent`, orange) used only for active states: current workspace, slider fill, toggles that are on, unread count. Every bar icon is in the accent, its text neutral. These are the defaults; the wallpaper replaces them (below).
- **Type.** The bar uses Iosevka Nerd Font Medium (`$font-bar`); popups use JetBrains Mono Nerd Font (`$font`).
- **Shape.** Cards and popups are rounded (`$radius`, `$radius-sm`). Hover and selection highlights use one subtle radius, `$radius-xs`; on the bar they are inset pills that stay off the bar edges.
- **Motion.** Popups fade in while rising a few pixels with an ease-out curve, and leave faster with an ease-in curve. `panel.sh` sets the `closing` var, waits for the exit animation, then closes the window. Hover and state changes cross-fade in 150ms; notifications slide in from the screen edge.

### Wallpaper colours

The accent, the three text colours and the grey surfaces follow the current wallpaper. Every bar icon is drawn in the accent (grey when off, red when hot or muted) with neutral text beside it. Black and red stay fixed. The colours are never generated: each one comes from a curated universe of soft dark-theme colours.

- **Sampling.** `scripts/theme.py` finds up to four prominent colours in the wallpaper's thumbnail (six frames of a GIF): every pixel votes for its hue (in OKLCH) weighted by its chroma, and each pick clears 45° around itself so the colours stay distinct. A mostly grey wallpaper keeps the Gruvbox palette.
- **Universe.** The accents of Gruvbox, Catppuccin, Rosé Pine, Tokyo Night, Nord, Everforest and Kanagawa (wave and dragon), kept only when they are pastel or dim: OKLCH chroma 0.045 to 0.115 and lightness 0.64 to 0.84 (`ACCENT_C`, `ACCENT_L`), so nothing vivid or near-white. Near-duplicates collapse onto the earlier theme. That leaves 33 colours.
- **Matching.** Each sampled colour takes the nearest universe colour by hue, with chroma weighed in so a muted wallpaper gets a muted accent. Gruvbox wins near-ties (`GRUVBOX_PULL`). A matched colour brings its theme's text colour along (Catppuccin text with a Catppuccin accent); surfaces stay near-black, faintly tinted toward that theme. Try it with `scripts/theme.py pick IMAGE`.
- **Choosing.** The picker footer shows the matched colours under the wallpaper name (hover for the name, such as "Catppuccin Lavender"), plus Gruvbox Orange. The first is the accent by default; click another to use it for this wallpaper (saved in `accents` in the state file), or Gruvbox to ignore the wallpaper. `wall.py accent N|default` does the same.
- **Palettes.** `scss/_themes.scss` holds one palette per universe colour. Regenerate it with `scripts/theme.py scss > scss/_themes.scss` after changing `FAMILIES` or the limits in `theme.py`.
- **Applying.** `wall.py` streams the wrapper classes to the `theme` var: `th-<colour>` for the accent, then `th2-` to `th4-` naming the other matched colours, which have no CSS and only feed the targets below. Every window's root is a `(box :class theme ...)` wrapper, and `eww.scss` includes `paint()` once per palette under its `.th-<colour>` class. Changing the wallpaper only swaps that class, so colours change live with no eww reload.
- **Rest of the desktop.** On every theme change `wall.py` also runs `scripts/theme.py apply CLASSES` (errors go to `~/.local/state/eww/theme.log`). It only rewrites a file whose content changes:

| Target | How | When it shows |
|---|---|---|
| niri | `~/.config/niri/eww-colors.kdl`, included last from `config.kdl`: focus ring (a gradient into the second colour when there is one), insert hint, tab indicator, Alt+Tab highlight | live (niri watches includes) |
| kitty | `~/.config/kitty/eww-colors.conf`, included last from `kitty.conf`: cursor, selection, borders and active tab in the accent, URLs in the second colour. The ANSI palette stays | live (SIGUSR1 reload) |
| Claude Code | `~/.claude/themes/wallpaper.json`, selected as `custom:wallpaper`: a copy of `gruvbox-amoled.json` with the accent (`claude`, the spinner and labels), the second colour (permission prompts, links, IDE) and the text colours swapped. Edit `gruvbox-amoled.json` for everything else | live (Claude Code watches `~/.claude/themes/`) |
| starship | `[palettes.wallpaper]` at the end of `~/.config/starship.toml`: gruvbox_dark with the four prompt segments in the wallpaper's colours, no lighter than Gruvbox orange so their text stays readable | next prompt |
| GTK3 apps | `gsettings gtk-theme`: the Orchis accent variant nearest the accent | live |
| GTK4 / libadwaita apps | `gsettings accent-color`: the nearest named accent, read through the portal | live |
| Qt apps | `~/.local/share/color-schemes/EwwDynamic.colors` (CosmicDark with its accent swapped), set in qt5ct/qt6ct | next app start |
| lazygit | `~/.config/lazygit/config.yml`: active border (accent) and options text (second colour) | next start |
| btop | `~/.config/btop/themes/wallpaper.theme` (`color_theme = "wallpaper"`): every colour from the palette; box outlines in the matched colours, graphs ramping up to them (temperature and used memory still end in red), black background | live (SIGUSR2) |
| swaylock | `~/.config/swaylock/config`: black screen, accent ring and key highlight | next lock |

Browsers and Electron apps (Chrome, Slack, VS Code) have no outside hook and keep their own colours. Terminal programs keep kitty's ANSI palette. The GTK and libadwaita accents come from fixed sets, so they are the nearest match rather than the exact colour.

## Debugging

```sh
tail -f ~/.cache/eww/daemon.log      # daemon + feeder stderr
eww state | less                     # every variable's current value
eww inspector                        # GTK inspector for CSS nodes
eww reload                           # restarts all feeders
~/.config/eww/launch.sh              # reopen bars, e.g. after plugging in a monitor
```

## Rollback

```sh
cp ~/.config/niri/config.kdl.bak-pre-eww ~/.config/niri/config.kdl
rm ~/.local/share/dbus-1/services/org.freedesktop.Notifications.service
eww kill; pkill -f eww/scripts/notifd.py; swaync & waybar &
```

The old waybar, rofi and swaync configs are still in place.

To stop the desktop-wide colours (eww keeps following the wallpaper): remove `apply` from `retheme()` in `wall.py`, then

```sh
for f in ~/.config/niri/config.kdl ~/.config/kitty/kitty.conf ~/.config/qt5ct/qt5ct.conf ~/.config/qt6ct/qt6ct.conf ~/.claude/settings.json ~/.config/starship.toml ~/.config/lazygit/config.yml ~/.config/btop/btop.conf; do cp "$f.bak-pre-theme" "$f"; done
gsettings set org.gnome.desktop.interface gtk-theme Orchis-Dark
gsettings set org.gnome.desktop.interface accent-color blue
rm ~/.config/swaylock/config; pkill -USR1 -x kitty
```
