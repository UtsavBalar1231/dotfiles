#!/usr/bin/env python3
"""Wallpaper-driven colours for the eww shell, drawn from a curated colour universe.

The wallpaper's prominent colours are sampled, then each is matched to the closest accent of a
well-known dark theme: Gruvbox first (the shell's own palette, which wins near-ties), then
Catppuccin, Rosé Pine, Tokyo Night, Nord, Everforest and Kanagawa (wave and dragon) for the
hues Gruvbox lacks. Only soft colours are used: pastel or dim, never vivid or near-white (see
ACCENT_L / ACCENT_C). A matched accent brings its theme's text colour with it; surfaces stay
near-black.

The shell cannot load new CSS without an eww reload (which rebuilds every window), so every
palette is generated ahead of time (scss/_themes.scss) and scoped under a class on each window's
wrapper box: `th-<colour>` for the accent. The class string also names the wallpaper's next
colours (`th2-` to `th4-`, no CSS), which `apply` hands to the rest of the desktop.

  theme.py scss          print scss/_themes.scss
  theme.py pick IMAGE    print the sampled colours, their matches and the theme classes
                         ("" = keep the default Gruvbox palette)
  theme.py apply CLASSES [STAMP]
                         colour the rest of the desktop to match (wall.py runs this on every
                         theme change; a run with an older STAMP than the last one is skipped)

`apply` targets: niri accents (~/.config/niri/eww-colors.kdl), kitty accents
(~/.config/kitty/eww-colors.conf, reloaded with SIGUSR1), GTK3 (the nearest Orchis accent
variant) and libadwaita (the nearest named accent) through gsettings, Qt (a copy of the
CosmicDark scheme with its accent swapped, read at app start), swaylock, Claude Code (the
`custom:wallpaper` theme, a copy of `custom:gruvbox-amoled` with its accents swapped; reloaded
live), the starship prompt (`[palettes.wallpaper]`, read at every prompt), btop (every colour,
reloaded live with SIGUSR2) and lazygit (read at start).
"""
import fcntl
import json
import math
import os
import re
import signal
import subprocess
import sys
import time

MAX_SEEDS = 4  # colours sampled from a wallpaper
SEPARATION = 45  # minimum degrees of hue between two sampled colours
MIN_SHARE = 0.12  # a colour needs this share of the strongest colour's vote to count
GRUVBOX_PULL = 0.75  # Gruvbox match distances are scaled by this, so it wins near-ties
CHROMA_WEIGHT = 200  # matching: 0.05 of OKLCH chroma counts as much as 10 degrees of hue
MIN_GAP = 20  # degrees of hue between the matched accents of one wallpaper
# The soft-colour window in OKLCH: chroma above 0.115 reads as vivid, lightness above 0.84 as
# near-white, chroma below 0.045 as grey. Lightness below 0.64 is too dark for text on black.
ACCENT_L, ACCENT_C = (0.64, 0.84), (0.045, 0.115)
FG_MAX_L = 0.9  # text no brighter than Gruvbox's cream

# family: (display name, text colour, background colour or None, accents). _universe keeps the
# accents inside the soft-colour window and drops near-duplicates in favour of the earlier family.
FAMILIES = {
    "gruvbox": ("Gruvbox", "#ebdbb2", None, {
        "red": "#ea6962", "orange": "#e78a4e", "yellow": "#d8a657", "green": "#a9b665",
        "aqua": "#89b482", "blue": "#7daea3", "purple": "#d3869b"}),
    "catppuccin": ("Catppuccin", "#cdd6f4", "#1e1e2e", {
        "pink": "#f5c2e7", "mauve": "#cba6f7", "red": "#f38ba8", "maroon": "#eba0ac", "peach": "#fab387",
        "yellow": "#f9e2af", "green": "#a6e3a1", "teal": "#94e2d5", "sky": "#89dceb",
        "sapphire": "#74c7ec", "blue": "#89b4fa", "lavender": "#b4befe"}),
    "rosepine": ("Rosé Pine", "#e0def4", "#191724", {
        "love": "#eb6f92", "gold": "#f6c177", "rose": "#ebbcba", "foam": "#9ccfd8", "iris": "#c4a7e7"}),
    "tokyonight": ("Tokyo Night", "#c0caf5", "#1a1b26", {
        "red": "#f7768e", "orange": "#ff9e64", "yellow": "#e0af68", "green": "#9ece6a",
        "teal": "#73daca", "cyan": "#7dcfff", "blue": "#7aa2f7", "magenta": "#bb9af7"}),
    "nord": ("Nord", "#eceff4", "#2e3440", {
        "frost-teal": "#8fbcbb", "frost-cyan": "#88c0d0", "frost-blue": "#81a1c1",
        "orange": "#d08770", "yellow": "#ebcb8b", "green": "#a3be8c", "purple": "#b48ead"}),
    "everforest": ("Everforest", "#d3c6aa", "#2d353b", {
        "red": "#e67e80", "orange": "#e69875", "yellow": "#dbbc7f", "green": "#a7c080",
        "aqua": "#83c092", "blue": "#7fbbb3", "purple": "#d699b6"}),
    "kanagawa": ("Kanagawa", "#dcd7ba", "#1f1f28", {
        "peach-red": "#ff5d62", "surimi-orange": "#ffa066", "carp-yellow": "#e6c384",
        "spring-green": "#98bb6c", "wave-aqua": "#7aa89f", "spring-blue": "#7fb4ca",
        "crystal-blue": "#7e9cd8", "oni-violet": "#957fb8", "sakura-pink": "#d27e99"}),
    "kanagawa-dragon": ("Kanagawa Dragon", "#c5c9c5", "#181616", {
        "red": "#c4746e", "orange": "#b6927b", "yellow": "#c4b28a", "green": "#87a987",
        "aqua": "#8ea4a2", "blue": "#8ba4b0", "violet": "#8992a7", "pink": "#a292a3"}),
}
# OKLCH lightness/chroma of the near-black surfaces, matching the Gruvbox greys in
# scss/_tokens.scss; other families tint them faintly with their background's hue.
NEUTRALS = {"surface": (0.164, 0.008), "raised": (0.205, 0.01), "hover": (0.255, 0.012), "border": (0.277, 0.012)}
FG_DIM_L, FG_MUTE_L = 0.755, 0.615  # lightness of the two dimmer text colours, as in Gruvbox


def _rgb(hexc: str) -> tuple[int, int, int]:
    return int(hexc[1:3], 16), int(hexc[3:5], 16), int(hexc[5:7], 16)


def _lin(c: float) -> float:
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def _gam(c: float) -> float:
    return 12.92 * c if c <= 0.0031308 else 1.055 * c ** (1 / 2.4) - 0.055


def to_oklch(r: int, g: int, b: int) -> tuple[float, float, float]:
    r, g, b = _lin(r / 255), _lin(g / 255), _lin(b / 255)
    l = (0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b) ** (1 / 3)
    m = (0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b) ** (1 / 3)
    s = (0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b) ** (1 / 3)
    L = 0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s
    A = 1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s
    B = 0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s
    return L, math.hypot(A, B), math.degrees(math.atan2(B, A)) % 360


def _linear_rgb(L: float, C: float, h: float) -> tuple[float, float, float]:
    A, B = C * math.cos(math.radians(h)), C * math.sin(math.radians(h))
    l = (L + 0.3963377774 * A + 0.2158037573 * B) ** 3
    m = (L - 0.1055613458 * A - 0.0638541728 * B) ** 3
    s = (L - 0.0894841775 * A - 1.2914855480 * B) ** 3
    return (4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
            -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
            -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s)


def to_hex(L: float, C: float, h: float) -> str:
    """OKLCH to sRGB hex, lowering chroma (not lightness) until the colour fits the gamut."""
    lo, hi = 0.0, C
    rgb = _linear_rgb(L, C, h)
    if not all(-1e-4 <= c <= 1 + 1e-4 for c in rgb):
        for _ in range(24):
            mid = (lo + hi) / 2
            if all(-1e-4 <= c <= 1 + 1e-4 for c in _linear_rgb(L, mid, h)):
                lo = mid
            else:
                hi = mid
        rgb = _linear_rgb(L, lo, h)
    return "#" + "".join(f"{round(_gam(min(max(c, 0.0), 1.0)) * 255):02x}" for c in rgb)


def _universe() -> dict[str, dict]:
    """Every usable accent by id (`<family>-<name>`), in family order.

    Only accents inside the soft-colour window are kept, minus any colour within a
    just-noticeable OKLab distance of one already kept."""
    out: dict[str, dict] = {}
    for fam, (fam_label, _, _, accents) in FAMILIES.items():
        for name, hexc in accents.items():
            L, C, h = to_oklch(*_rgb(hexc))
            if not (ACCENT_L[0] <= L <= ACCENT_L[1] and ACCENT_C[0] <= C <= ACCENT_C[1]):
                continue
            a, b = C * math.cos(math.radians(h)), C * math.sin(math.radians(h))
            if any(math.dist((L, a, b), o["lab"]) < 0.025 for o in out.values()):
                continue
            out[f"{fam}-{name}"] = {"hex": hexc, "family": fam, "L": L, "C": C, "h": h, "lab": (L, a, b),
                                    "label": f"{fam_label} {name.replace('-', ' ').title()}"}
    return out


def _palette_for(cid: str) -> dict:
    col = COLORS[cid]
    if col["family"] == "gruvbox":
        p = dict(DEFAULT)
    else:
        _, text, bg, _ = FAMILIES[col["family"]]
        tL, tC, th = to_oklch(*_rgb(text))
        bh = to_oklch(*_rgb(bg))[2]
        p = {"fg": text if tL <= FG_MAX_L else to_hex(FG_MAX_L, tC, th),
             "fg-dim": to_hex(FG_DIM_L, tC, th), "fg-mute": to_hex(FG_MUTE_L, tC * 0.9, th)}
        p.update({k: to_hex(L, C, bh) for k, (L, C) in NEUTRALS.items()})
    p["accent"] = col["hex"]
    return p


def scss() -> str:
    keys = ("accent", "fg", "fg-dim", "fg-mute", "surface", "raised", "hover", "border")
    out = ["// Generated by scripts/theme.py scss: one palette per accent of the colour universe,",
           "// applied as a `.th-<colour>` class.", "$themes: ("]
    for cid in COLORS:
        p = _palette_for(cid)
        out.append(f"  th-{cid}: (" + ", ".join(f"{k}: {p[k]}" for k in keys) + "),")
    out.append(");")
    return "\n".join(out) + "\n"


def _pixels(image_path: str) -> list[tuple[int, int, int]]:
    """Opaque pixels of a small copy of the image; for a GIF, of 6 frames spread over it."""
    from PIL import Image
    px = []
    with Image.open(image_path) as im:
        im.draft("RGB", (192, 192))  # JPEG: decode at reduced size
        n = getattr(im, "n_frames", 1)
        for frame in sorted({round(k * (n - 1) / 5) for k in range(6)}):
            im.seek(frame)
            small = im.convert("RGBA")
            small.thumbnail((96, 96))
            b = small.tobytes()
            px += [(b[i], b[i + 1], b[i + 2]) for i in range(0, len(b), 4) if b[i + 3] > 128]
    return px


def samples(image_path: str) -> list[tuple[float, float]]:
    """The image's prominent colours as (OKLCH hue, chroma), strongest first; [] when mostly grey.

    Each pixel votes for its hue with its chroma, so a large, strongly coloured area wins over
    both small vivid details and big washed-out ones. The vote is smoothed over +-15 degrees;
    each pick then clears SEPARATION degrees around itself so the colours stay distinct. A
    colour's chroma is the mean chroma of the pixels that voted for it."""
    px = _pixels(image_path)
    votes, counts = [0.0] * 360, [0] * 360
    for r, g, b in px:
        L, C, h = to_oklch(r, g, b)
        if C >= 0.03 and 0.15 <= L <= 0.95:
            votes[int(h) % 360] += C
            counts[int(h) % 360] += 1
    if not px or sum(counts) < 0.08 * len(px):
        return []
    window = lambda c: [(c + d) % 360 for d in range(-15, 16)]  # noqa: E731
    score = [sum(votes[i] for i in window(c)) for c in range(360)]
    top, out = max(score), []
    while len(out) < MAX_SEEDS:
        c = max(range(360), key=score.__getitem__)
        if score[c] <= 0 or score[c] < MIN_SHARE * top:
            break
        out.append((float(c), score[c] / max(1, sum(counts[i] for i in window(c)))))
        for d in range(-SEPARATION, SEPARATION + 1):
            score[(c + d) % 360] = 0
    return out


def _hue_gap(a: float, b: float) -> float:
    return min(abs(a - b), 360 - abs(a - b))


def match(found: list[tuple[float, float]]) -> list[str]:
    """Universe colour ids for sampled (hue, chroma) colours, in the same order.

    Nearest by hue, with chroma weighed in so a muted wallpaper colour lands on a soft accent
    and a vivid one on a strong accent; Gruvbox distances shrink by GRUVBOX_PULL. Each id stays
    MIN_GAP degrees from those already taken, so one wallpaper never yields two near-identical
    accents."""
    out: list[str] = []
    for h, c in found:
        free = [cid for cid in COLORS if all(_hue_gap(COLORS[cid]["h"], COLORS[o]["h"]) >= MIN_GAP for o in out)]
        if free:
            out.append(min(free, key=lambda cid: math.hypot(_hue_gap(h, COLORS[cid]["h"]),
                                                            CHROMA_WEIGHT * (c - COLORS[cid]["C"]))
                           * (GRUVBOX_PULL if COLORS[cid]["family"] == "gruvbox" else 1)))
    return out


def classes(ids: list[str], pick: int = 0) -> str:
    """Wrapper classes for matched colours: `th-` for colour `pick` (the accent), then `th2-` to
    `th4-` for the others, strongest first. pick -1, or no colours, keeps the default Gruvbox."""
    if pick < 0 or not ids:
        return ""
    pick = pick if pick < len(ids) else 0
    order = [ids[pick]] + [cid for i, cid in enumerate(ids) if i != pick]
    # Only th- has CSS; th2- to th4- hand the other colours to `apply` (niri, kitty, prompt, Claude Code).
    return " ".join(f"{role}-{cid}" for role, cid in zip(("th", "th2", "th3", "th4"), order))


# Mirrors $default-palette in scss/_tokens.scss: the colours used when no theme class is set.
DEFAULT = {"accent": "#e78a4e", "fg": "#ebdbb2", "fg-dim": "#bdae93", "fg-mute": "#928374",
           "surface": "#0e0e0e", "raised": "#171717", "hover": "#232323", "border": "#282828"}
RED = "#ea6962"
# Accent colours of the installed Orchis GTK3 variants and of libadwaita's named accents;
# each target takes the one whose hue is nearest the palette's accent.
ORCHIS = {"Orchis-Dark": "#3281ea", "Orchis-Green-Dark": "#66bb6a", "Orchis-Orange-Dark": "#fb8c00",
          "Orchis-Pink-Dark": "#f06292", "Orchis-Purple-Dark": "#ba68c8", "Orchis-Red-Dark": "#f44336",
          "Orchis-Teal-Dark": "#4db6ac", "Orchis-Yellow-Dark": "#fbc02d"}
ADWAITA = {"blue": "#3584e4", "teal": "#2190a4", "green": "#3a944a", "yellow": "#c88800",
           "orange": "#ed5b00", "red": "#e62d42", "pink": "#d56199", "purple": "#9141ac"}
COLORS = _universe()
HOME = os.path.expanduser("~")
QT_BASE = f"{HOME}/.local/share/color-schemes/CosmicDark.colors"
QT_OUT = f"{HOME}/.local/share/color-schemes/EwwDynamic.colors"
QT_ACCENT, QT_ACCENT_DIM = "99,208,223", "63,118,125"  # CosmicDark's cyan and its dimmed form
CLAUDE_BASE = f"{HOME}/.claude/themes/gruvbox-amoled.json"
CLAUDE_OUT = f"{HOME}/.claude/themes/wallpaper.json"
STARSHIP = f"{HOME}/.config/starship.toml"
STARSHIP_SEGMENTS = ("color_orange", "color_yellow", "color_aqua", "color_blue")  # left to right
STARSHIP_MAX_L = 0.72  # OKLCH lightness of Gruvbox orange, the preset's own segment colour
LAZYGIT = f"{HOME}/.config/lazygit/config.yml"
BTOP_BASE = "/usr/share/btop/themes/gruvbox_dark.theme"
BTOP_OUT = f"{HOME}/.config/btop/themes/wallpaper.theme"


def palette(cls: str) -> dict:
    """Colours for wrapper classes: the `th-` palette (or Gruvbox), plus accent2/accent3 from
    `th2-`/`th3-`/`th4-` when the wallpaper had more colours."""
    roles = {m[1]: m[2] for c in cls.split() if (m := re.fullmatch(r"(th[234]?)-([a-z]+(?:-[a-z]+)+)", c)) and m[2] in COLORS}
    p = _palette_for(roles["th"]) if "th" in roles else dict(DEFAULT)
    for role, key in (("th2", "accent2"), ("th3", "accent3"), ("th4", "accent4")):
        if role in roles:
            p[key] = COLORS[roles[role]]["hex"]
    return p


def nearest(hexc: str, options: dict[str, str]) -> str:
    h = to_oklch(*_rgb(hexc))[2]
    dist = lambda o: min(abs(h - to_oklch(*_rgb(o))[2]), 360 - abs(h - to_oklch(*_rgb(o))[2]))  # noqa: E731
    return min(options, key=lambda name: dist(options[name]))


def write(path: str, text: str) -> bool:
    """Atomically replace `path` with `text`; False (and no write) when it already matches."""
    try:
        with open(path) as f:
            if f.read() == text:
                return False
    except OSError:
        pass
    os.makedirs(os.path.dirname(path), exist_ok=True)
    tmp = f"{path}.{os.getpid()}.tmp"
    with open(tmp, "w") as f:
        f.write(text)
    os.replace(tmp, path)
    return True


def apply_niri(p: dict):
    a = p["accent"]
    # With a second wallpaper colour the ring runs from the accent into it.
    gradient = (f'\n        active-gradient from="{a}dd" to="{p["accent2"]}dd" angle=45 in="oklch shorter hue"'
                if "accent2" in p else "")
    write(f"{HOME}/.config/niri/eww-colors.kdl", f"""\
// Managed by ~/.config/eww/scripts/theme.py: niri accents follow the wallpaper.
// Included last from config.kdl, so these colours override the ones set there.
layout {{
    focus-ring {{
        active-color "{a}dd"{gradient}
    }}
    insert-hint {{
        color "{a}80"
    }}
    tab-indicator {{
        active-color "{a}"
    }}
}}
recent-windows {{
    highlight {{
        active-color "{a}ff"
    }}
}}
""")  # niri watches included files and reloads by itself


def apply_kitty(p: dict):
    a = p["accent"]
    if write(f"{HOME}/.config/kitty/eww-colors.conf", f"""\
# Managed by ~/.config/eww/scripts/theme.py: accent colours follow the wallpaper.
# Included last from kitty.conf; the ANSI palette stays as current-theme.conf sets it.
cursor                {a}
url_color             {p.get("accent2", a)}
selection_foreground  #000000
selection_background  {a}
active_border_color   {a}
inactive_border_color {p["border"]}
active_tab_foreground {a}
"""):
        uid = os.getuid()
        for pid in filter(str.isdigit, os.listdir("/proc")):
            try:
                with open(f"/proc/{pid}/comm") as f:
                    if f.read().strip() == "kitty" and os.stat(f"/proc/{pid}").st_uid == uid:
                        os.kill(int(pid), signal.SIGUSR1)  # kitty reloads kitty.conf on SIGUSR1
            except OSError:
                pass


def apply_gtk(p: dict):
    want = {"gtk-theme": nearest(p["accent"], ORCHIS), "accent-color": nearest(p["accent"], ADWAITA)}
    for key, val in want.items():
        cur = subprocess.run(["gsettings", "get", "org.gnome.desktop.interface", key],
                             capture_output=True, text=True).stdout.strip().strip("'")
        if cur != val:
            subprocess.run(["gsettings", "set", "org.gnome.desktop.interface", key, val], check=True)


def apply_qt(p: dict):
    if not os.path.exists(QT_BASE):
        return
    a = _rgb(p["accent"])
    with open(QT_BASE) as f:
        text = f.read()
    text = (text.replace(f"={QT_ACCENT}", "=" + ",".join(map(str, a)))
            .replace(f"={QT_ACCENT_DIM}", "=" + ",".join(str(round(c * 0.55)) for c in a))
            .replace("ColorScheme=CosmicDark", "ColorScheme=EwwDynamic")
            .replace("Name=COSMIC Dark", "Name=Eww Dynamic"))
    write(QT_OUT, text)


def apply_swaylock(p: dict):
    c = {k: v.lstrip("#") for k, v in p.items()}
    red, clear = RED.lstrip("#"), "00000000"
    write(f"{HOME}/.config/swaylock/config", f"""\
# Managed by ~/.config/eww/scripts/theme.py: lock screen colours follow the wallpaper.
color=000000
font=JetBrainsMono Nerd Font Propo
indicator-radius=90
indicator-thickness=7
inside-color={clear}
inside-clear-color={clear}
inside-ver-color={clear}
inside-wrong-color={clear}
line-color={clear}
line-clear-color={clear}
line-ver-color={clear}
line-wrong-color={clear}
separator-color={clear}
ring-color={c["border"]}
ring-clear-color={c["fg-mute"]}
ring-ver-color={c["accent"]}
ring-wrong-color={red}
key-hl-color={c["accent"]}
bs-hl-color={red}
text-color={c["fg"]}
text-clear-color={c["fg-mute"]}
text-ver-color={c["accent"]}
text-wrong-color={red}
""")


def _lighter(hexc: str, by: float = 0.08) -> str:
    L, C, h = to_oklch(*_rgb(hexc))
    return to_hex(min(L + by, 0.95), C, h)


def apply_claude(p: dict):
    if not os.path.exists(CLAUDE_BASE):
        return
    with open(CLAUDE_BASE) as f:
        theme = json.load(f)
    a, a2 = p["accent"], p.get("accent2", p["accent"])
    theme["name"] = "Wallpaper"
    theme["overrides"].update({
        "claude": a, "claudeShimmer": _lighter(a), "briefLabelClaude": a, "rate_limit_fill": a,
        "permission": a2, "permissionShimmer": _lighter(a2), "bashBorder": a2,
        "link": a2, "ide": a2, "briefLabelYou": a2,
        "text": p["fg"], "suggestion": p["fg-dim"], "inactive": p["fg-mute"], "inactiveShimmer": p["fg-dim"],
    })
    write(CLAUDE_OUT, json.dumps(theme, indent=2) + "\n")


def apply_starship(p: dict):
    """Rewrite `[palettes.wallpaper]`: gruvbox_dark with the segment colours from the wallpaper."""
    if not os.path.exists(STARSHIP):
        return
    with open(STARSHIP) as f:
        text = f.read()
    base = re.search(r"^\[palettes\.gruvbox_dark\]\n((?:\w+ = '#[0-9a-fA-F]{6}'\n)+)", text, re.M)
    if not base:
        return
    colours = dict(re.findall(r"^(\w+) = '(#[0-9a-fA-F]{6})'$", base[1], re.M))
    for name, key in zip(STARSHIP_SEGMENTS, ("accent", "accent2", "accent3", "accent4")):
        if key in p:  # the segments carry near-white text, so they stay no lighter than Gruvbox's
            L, C, h = to_oklch(*_rgb(p[key]))
            colours[name] = to_hex(min(L, STARSHIP_MAX_L), C, h)
    block = ("[palettes.wallpaper]\n# Managed by ~/.config/eww/scripts/theme.py: gruvbox_dark with the "
             "segments in the wallpaper's colours.\n" + "".join(f"{k} = '{v}'\n" for k, v in colours.items()))
    old = re.search(r"^\[palettes\.wallpaper\]\n(?:#.*\n|\w+ = '#[0-9a-fA-F]{6}'\n)*", text, re.M)
    text = text[:old.start()] + block + text[old.end():] if old else text.rstrip("\n") + "\n\n" + block
    write(STARSHIP, text)


def apply_lazygit(p: dict):
    if not os.path.exists(LAZYGIT):
        return
    with open(LAZYGIT) as f:
        text = f.read()
    for key, col in (("activeBorderColor", p["accent"]), ("optionsTextColor", p.get("accent2", p["accent"]))):
        text = re.sub(rf'(^\s*{key}:\n\s*- )"#[0-9a-fA-F]{{6}}"', rf'\g<1>"{col}"', text, flags=re.M)
    write(LAZYGIT, text)


def _shade(hexc: str, L: float, chroma: float = 1.0) -> str:
    """The colour at OKLCH lightness L, with its chroma scaled by `chroma`."""
    _, C, h = to_oklch(*_rgb(hexc))
    return to_hex(L, C * chroma, h)


def _btop_hot_reloads() -> bool:
    """True when the installed btop hot-reloads on SIGUSR2 (1.3.2+); older ones die from it."""
    out = subprocess.run(["btop", "--version"], capture_output=True, text=True).stdout
    m = re.search(r"(\d+)\.(\d+)\.(\d+)", re.sub(r"\x1b\[[0-9;]*m", "", out))
    return bool(m) and tuple(map(int, m.groups())) >= (1, 3, 2)


def apply_btop(p: dict):
    """btop: every colour from the palette. Graphs ramp from a dim shade up to their colour (or
    to red for temperature and used memory, which keep their warning meaning); box outlines are
    dimmed shades of the wallpaper's matched colours. Running btops reload it on SIGUSR2."""
    if not os.path.exists(BTOP_BASE):
        return
    a = p["accent"]
    a2 = p.get("accent2", a)
    a3 = p.get("accent3", a2)
    a4 = p.get("accent4", a3)
    ramp = lambda c, end=None: (_shade(c, 0.42, 0.55), _shade(c, 0.58, 0.8), end or c)  # noqa: E731
    colours = {
        "main_bg": "#000000", "main_fg": p["fg-dim"], "title": p["fg"], "hi_fg": a,
        "selected_bg": p["hover"], "selected_fg": a, "inactive_fg": p["fg-mute"], "graph_text": p["fg-dim"],
        "proc_misc": a2, "div_line": _shade(p["fg-mute"], 0.42),
        "cpu_box": _shade(a, 0.55, 0.8), "mem_box": _shade(a2, 0.55, 0.8),
        "net_box": _shade(a3, 0.55, 0.8), "proc_box": _shade(a4, 0.55, 0.8),
    }
    for graph, (colour, end) in {"temp": (a, RED), "cpu": (a, None), "free": (a2, None), "cached": (a3, None),
                                 "available": (a4, None), "used": (a, RED), "download": (a2, None),
                                 "upload": (a3, None), "process": (a, None)}.items():
        colours.update(zip((f"{graph}_start", f"{graph}_mid", f"{graph}_end"), ramp(colour, end)))
    with open(BTOP_BASE) as f:
        text = f.read()
    for key, col in colours.items():
        text, n = re.subn(rf'^theme\[{key}\]=".*"$', f'theme[{key}]="{col}"', text, flags=re.M)
        if not n:
            text += f'theme[{key}]="{col}"\n'
    if write(BTOP_OUT, "# Managed by ~/.config/eww/scripts/theme.py: btop colours follow the wallpaper.\n" + text) \
            and _btop_hot_reloads():
        uid = os.getuid()
        for pid in filter(str.isdigit, os.listdir("/proc")):
            try:
                with open(f"/proc/{pid}/comm") as f:
                    if f.read().strip() == "btop" and os.stat(f"/proc/{pid}").st_uid == uid:
                        os.kill(int(pid), signal.SIGUSR2)
            except OSError:
                pass


TARGETS = {"niri": apply_niri, "kitty": apply_kitty, "gtk": apply_gtk, "qt": apply_qt, "swaylock": apply_swaylock,
           "claude": apply_claude, "starship": apply_starship, "lazygit": apply_lazygit, "btop": apply_btop}


def apply(cls: str, stamp: float):
    runtime = os.environ.get("XDG_RUNTIME_DIR", "/tmp")
    with open(f"{runtime}/eww-theme.lock", "a+") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        lock.seek(0)
        try:
            if stamp < float(lock.read() or 0):
                return  # a newer theme was applied while this run waited
        except ValueError:
            pass
        p = palette(cls)
        for name, target in TARGETS.items():
            try:
                target(p)
            except Exception as e:  # one broken target must not keep the others stale
                print(f"theme: {name}: {e}", file=sys.stderr)
        lock.seek(0)
        lock.truncate()
        lock.write(str(stamp))


if __name__ == "__main__":
    if sys.argv[1:2] == ["scss"]:
        sys.stdout.write(scss())
    elif sys.argv[1:2] == ["pick"] and len(sys.argv) == 3:
        found = samples(sys.argv[2])
        for (h, c), cid in zip(found, match(found)):
            print(f"hue {h:5.1f} chroma {c:.3f} -> {COLORS[cid]['label']} {COLORS[cid]['hex']}")
        print("classes:", repr(classes(match(found))))
    elif sys.argv[1:2] == ["apply"] and len(sys.argv) in (3, 4):
        apply(sys.argv[2], float(sys.argv[3]) if len(sys.argv) == 4 else time.time())
    else:
        print(__doc__, file=sys.stderr)
        sys.exit(1)
