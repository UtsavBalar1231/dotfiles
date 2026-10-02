# macOS Spotlight Theme for Anyrun

This theme transforms [Anyrun](https://github.com/anyrun-org/anyrun) into a macOS Spotlight-like launcher with a clean, minimalist design.

## Installation

1. First, make sure you have Anyrun installed. If not, follow the installation instructions on the [Anyrun GitHub page](https://github.com/anyrun-org/anyrun).

2. Copy the files to your Anyrun configuration directory:

```bash
mkdir -p ~/.config/anyrun
cp style.css ~/.config/anyrun/
cp config.ron ~/.config/anyrun/
```

3. Restart Anyrun for the changes to take effect.

## Features

- Clean, minimalist design inspired by macOS Spotlight
- Translucent background with proper blur effect
- macOS-like typography and spacing
- Smooth animations and transitions
- Proper highlighting for selected items

## Customization

You can customize this theme by editing the `style.css` file. Some quick customizations:

- Change the background color in the `window` selector
- Adjust the width and positioning in the `config.ron` file
- Modify font families, sizes, and colors to match your preferences

## Font Recommendations

For the most authentic macOS Spotlight experience, install these fonts:
- SF Pro Display
- SF Pro Text

If these fonts are not available, the theme will fall back to Helvetica Neue or your system sans-serif font.

## Troubleshooting

- If the theme doesn't appear to be applied, check that the `css_file` in `config.ron` points to the correct location of your CSS file.
- Make sure Anyrun is configured to use your custom configuration by setting the correct configuration directory.
- For CSS syntax errors, refer to the GTK3 CSS documentation as it differs from standard web CSS in several ways:
  - Some pseudo-classes like `:hover` and `:focus` work similarly to web CSS
  - For styling placeholders, use `-gtk-secondary-caret-color` instead of web CSS placeholder approaches
  - GTK3 has specific properties like `-gtk-icon-source` and `-gtk-icon-theme` for icon handling

## GTK3 CSS Compatibility Notes

This theme was designed to be compatible with GTK3's CSS implementation, which differs from standard web CSS. Some key differences:

- GTK3 uses specific pseudo-class names
- Element selectors follow the GTK widget hierarchy
- Many CSS properties have GTK-specific equivalents with `-gtk-` prefixes
- Not all standard CSS features are supported

For more information, refer to the [GTK3 CSS Overview](https://docs.gtk.org/gtk3/css-overview.html).

## Credits

- This theme was designed to mimic the look and feel of macOS Spotlight
- [Anyrun](https://github.com/anyrun-org/anyrun) - A wayland native, highly customizable launcher 