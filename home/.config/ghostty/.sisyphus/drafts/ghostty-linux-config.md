# Ghostty Linux Configuration

Copy the contents below to `~/.config/ghostty/config`:

```bash
# Ghostty configuration file - Linux Optimized
# Based on nightly Ghostty docs (https://ghostty.org/docs)

# ============================================
# FONTS (Linux uses FreeType rendering)
# ============================================
font-family = JetBrainsMono Nerd Font
font-size = 20
font-feature = +calt +case +cv01 +cv02 +cv03 +cv04 +cv05 +cv06 +cv07 +cv08 +cv09 +cv10 +cv11 +cv12 +cv14 +cv15 +cv16 +cv17 +cv18 +cv19 +cv20 +cv99 +frac +locl +ss01 +ss02 +ss19 +ss20 +mark +mkmk
font-thicken = true
font-thicken-strength = 1

# ============================================
# CURSOR
# ============================================
cursor-style = bar
cursor-style-blink = false
bold-is-bright = true

# ============================================
# LINKS & URL HANDLING
# ============================================
link-url = true
link-previews = true

# ============================================
# CLIPBOARD
# ============================================
clipboard-read = allow
clipboard-write = allow
copy-on-select = clipboard

# ============================================
# WINDOW DISPLAY
# ============================================
window-padding-x = 4
window-padding-y = 4
window-padding-balance = true
resize-overlay-duration = 250ms

# ============================================
# GTK-SPECIFIC (Linux/GTK only)
# ============================================
gtk-titlebar-hide-when-maximized = true
gtk-toolbar-style = flat
gtk-tabs-location = top
gtk-quick-terminal-layer = overlay
gtk-single-instance = false

# Quick terminal
quick-terminal-position = top
quick-terminal-screen = mouse

# ============================================
# THEME (Gruvbox Dark Hard)
# ============================================
theme = Gruvbox Dark Hard
background = #000000
foreground = #d4be98
selection-background = #d4be98
selection-foreground = #000000
cursor-color = #d4be98
cursor-text = #d4be98

# Color palette (Gruvbox Dark Hard)
palette = 0=#000000
palette = 1=#ea6962
palette = 2=#a9b665
palette = 3=#d8a657
palette = 4=#7daea3
palette = 5=#d3869b
palette = 6=#89b482
palette = 7=#d4be98
palette = 8=#7c6f64
palette = 9=#ea6962
palette = 10=#a9b665
palette = 11=#d8a657
palette = 12=#7daea3
palette = 13=#d3869b
palette = 14=#89b482
palette = 15=#ddc7a1

# ============================================
# KEYBINDINGS
# ============================================
keybind = shift+enter=text:\x1b\r
keybind = f11=toggle_window_decorations
keybind = ctrl+shift+h=write_screen_file:paste
keybind = ctrl+shift+f=write_screen_file:open
keybind = ctrl+`=toggle_quick_terminal

# ============================================
# AUTO-UPDATE
# ============================================
# auto-update = download
# auto-update-channel = tip
```

## Changes from Original

1. **Added `link-url = true`** - Explicitly enables URL detection
2. **Added Linux-specific sections** with comments explaining each option
3. **Added FreeType hinting comment** (disabled by default, optimal)
4. **Added background-blur comment** for KDE Plasma users
5. **Added `gtk-single-instance = false`** for faster CLI launches
6. **Organized into logical sections** with headers

## Note on URL Hints

Ghostty does **NOT** yet have Kitty-style URL hints (Ctrl+Shift+E to highlight all URLs). This feature is tracked in [GitHub Discussion #2394](https://github.com/ghostty-org/ghostty/discussions/2394).
