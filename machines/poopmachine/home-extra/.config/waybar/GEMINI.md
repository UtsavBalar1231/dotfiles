# Waybar Configuration (Niri)

This directory contains the configuration for **Waybar**, tailored for the **Niri** Wayland compositor. It features a Gruvbox Material Hard Dark theme and integrates with various system utilities.

## Project Structure

*   **`config.jsonc`**: The main configuration file defining the bar's layout, position, and active modules. It uses JSONC (JSON with comments).
*   **`style.css`**: The master stylesheet. It imports color variables and defines the visual appearance of the bar and its modules.
*   **`themes/`**: Contains theme definitions.
    *   `gruvbox.css`: Defines the Gruvbox Material color palette used by `style.css`.
*   **`scripts/`**: Shell scripts used by custom modules for interactivity.
    *   `rofi-powermenu.sh`: A Rofi-based power menu (Shutdown, Reboot, Suspend, Lock, Logout).
    *   `rofi-network.sh`: (Presumed) Rofi interface for network management.
    *   `rofi-clipboard.sh`: (Presumed) Rofi interface for clipboard history.

## Key Features

*   **Compositor**: Designed for **Niri** (`niri/workspaces`, `niri/window`).
*   **Theme**: Gruvbox Material Hard Dark (High contrast, AMOLED black background).
*   **Fonts**: configured for **Iosevka Nerd Font** and **JetBrainsMono Nerd Font**.
*   **Modules**:
    *   **Left**: Application Launcher (Rofi), Window Title.
    *   **Center**: Workspaces.
    *   **Right**: Media Player (MPRIS), Tray, System Stats (Disk, CPU, RAM), Network, Bluetooth, Audio, Notifications (SwayNC), Power Menu, Clock.

## Dependencies

To fully utilize this configuration, the following software is expected:

*   **Waybar**: The status bar itself.
*   **Niri**: The Wayland compositor.
*   **Rofi**: For the launcher and custom menus (power, network).
*   **SwayNC**: For the notification center (`swaync-client`).
*   **Nerd Fonts**: Specifically Iosevka or JetBrainsMono for icons.
*   **Playerctl**: For media control (`mpris` module).

## Usage & Commands

### Reload Configuration

Waybar typically reloads automatically when the config file is saved (`"reload_style_on_change": true` is enabled in config).

To manually reload waybar (if running):

```bash
killall -SIGUSR2 waybar
```

### Edit Configuration

*   **Layout**: Edit `config.jsonc` to add/remove modules or change their order.
*   **Styling**: Edit `style.css` to change fonts, spacing, or specific module colors.
*   **Colors**: Edit `themes/gruvbox.css` to adjust the global color palette.
