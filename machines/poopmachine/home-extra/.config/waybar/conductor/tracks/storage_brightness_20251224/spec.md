# Specification: Storage and Brightness Enhancements

## 1. Overview
This track introduces support for multiple storage drives with dynamic detection and implements a comprehensive brightness control module that supports both local display and external monitors via `ddcutil`.

## 2. Functional Requirements
### Storage Management
- **Dynamic Detection:** Implement logic (via custom script or advanced Waybar config) to monitor `/` and `/home` specifically.
- **Visuals:** Display separate icons/percentages for each drive.

### Brightness Control
- **DDC/CI Support:** Integrate `ddcutil` to control external monitor brightness.
- **Scroll interaction:** Enable brightness adjustment via mouse scroll over the Waybar module.
- **GUI Launcher:** Left-click triggers a Rofi-based brightness menu or external control tool.

## 3. Technical Constraints
- **Backend:** `ddcutil` must be installed and the user must have permissions (usually via `i2c` group) to access monitor controls.
- **Storage:** Use standard `df` or Waybar's internal `disk` module logic for usage stats.

## 4. Acceptance Criteria
- Storage module correctly shows `/` and `/home` usage.
- Scrolling on the brightness module changes the monitor/screen brightness.
- Left-clicking the brightness module launches the specified GUI/Rofi script.

## 5. Out of Scope
- Controlling individual RGB channels of monitors.
- Dynamic partitioning or disk management.
