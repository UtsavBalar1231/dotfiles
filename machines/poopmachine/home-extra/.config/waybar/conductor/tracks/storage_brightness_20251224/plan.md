# Plan: Storage and Brightness Enhancements

## Phase 1: storage_implementation
- [x] Task: Configure dynamic storage modules in `config.jsonc`.
    - Add/Update `disk` modules for `/` and `/home`.
    - Ensure icons clearly distinguish between root and home.
- [x] Task: Style the storage modules in `style.css`.
    - Apply Gruvbox colors (`@color2` for root, `@color4` for home).
    - Ensure unified padding and margins.

## Phase 2: brightness_implementation
- [x] Task: Create a custom brightness script (e.g., `scripts/brightness.sh`).
    - Implement `get` and `set` logic using `ddcutil` (for monitors) and `brightnessctl` (for local display).
    - Add support for incremental changes (up/down).
- [x] Task: Implement Rofi brightness menu.
    - Create `scripts/rofi-brightness.sh` to provide a visual slider or preset levels (25%, 50%, 75%, 100%).
- [x] Task: Configure the `custom/brightness` module in `config.jsonc`.
    - Map `on-scroll-up` and `on-scroll-down` to the brightness script.
    - Map `on-click` to the Rofi brightness menu.
- [x] Task: Style the brightness module in `style.css`.
    - Use `@color3` (Yellow) for the brightness icon.

## Phase 3: verification_and_cleanup
- [x] Task: Verify storage detection.
    - Confirm both `/` and `/home` are visible and updating.
- [x] Task: Test brightness interactions.
    - Verify scroll-to-adjust works for both laptop screen and external monitors (where supported).
    - Verify Rofi menu launches and applies changes.
