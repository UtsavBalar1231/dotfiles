# Product Guidelines

## Design Principles

### Visual Identity
- **Theme:** Strictly adhere to the **Gruvbox Material Hard Dark** color palette.
- **Background:** Use "AMOLED Black" (`#000000`) for the main bar background to ensure high contrast and seamless integration with OLED screens.
- **Typography:** Use **Nerd Fonts** exclusively. The primary preference is **Iosevka Nerd Font**, with **JetBrainsMono Nerd Font** as a fallback. Font weights should generally be 500 or 600 for legibility.
- **Iconography:** Utilize Nerd Font icons for all modules to maintain a unified visual language.

### User Experience (UX)
- **Minimalism:** Display information concisely. Use tooltips for detailed metrics (e.g., exact IP address, detailed battery health) to keep the bar uncluttered.
- **Interactivity:** Every module should have a meaningful click action (e.g., clicking the clock opens a calendar, clicking CPU opens a task manager).
- **Responsiveness:** Scripts (like the power menu) should execute immediately and provide feedback (e.g., via `notify-send`) if dependencies are missing.

## Coding Conventions

### Configuration (JSONC)
- **Structure:** Group related modules logically (Left: Navigation/Window, Center: Workspaces, Right: Status/System).
- **Comments:** Use comments `//` to explain complex regex rewrites or custom script logic.

### Styling (CSS)
- **Modularity:** Keep color definitions in a separate file (`themes/gruvbox.css`) and import them.
- **Selectors:** Use specific ID selectors (e.g., `#workspaces button.active`) over broad class selectors to prevent style leakage.

### Scripting (Bash)
- **Portability:** Check for dependencies (like `rofi`, `swaylock`) at the start of scripts and fail gracefully if they are missing.
- **Safety:** Use quoting for variables to prevent issues with spaces in filenames or paths.
