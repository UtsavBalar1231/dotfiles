---@class neovide
local M = {}

-- Only apply Neovide configuration when running in Neovide
if not vim.g.neovide then
	return M
end

-- Set GUI font for proper rendering
vim.o.guifont = "JetBrainsMono Nerd Font:h16"

-- line spacing
vim.opt.linespace = 0

-- scale factor
vim.g.neovide_scale_factor = 1.0

-- text gamma and contrast
vim.g.neovide_text_gamma = 0.0
vim.g.neovide_text_contrast = 0.5

-- padding
vim.g.neovide_padding_top = 4.0
vim.g.neovide_padding_bottom = 4.0
vim.g.neovide_padding_right = 4.0
vim.g.neovide_padding_left = 4.0

-- titlebar settings
-- Safely get background color with fallback
local bg_color = "#1e1e2e" -- Default fallback color
local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = "Normal", link = false })
if ok and hl.bg then
	bg_color = string.format("#%06x", hl.bg)
end
vim.g.neovide_title_background_color = bg_color
vim.g.neovide_title_text_color = "#f5c2e7" -- Use hex color for consistency
vim.g.neovide_window_blurred = true

-- floating blur
vim.g.neovide_floating_blur_amount_x = 8.0
vim.g.neovide_floating_blur_amount_y = 8.0

-- floating shadows
vim.g.neovide_floating_shadow = true
vim.g.neovide_floating_z_height = 8
vim.g.neovide_light_angle_degrees = 45
vim.g.neovide_light_radius = 5

-- floating corners
vim.g.neovide_floating_corner_radius = 12.0

-- transparency
-- vim.g.neovide_opacity = 0.85
-- vim.g.neovide_normal_opacity = 0.90

-- animations
vim.g.neovide_position_animation_length = 0.0
vim.g.neovide_scroll_animation_length = 0.0
vim.g.neovide_scroll_animation_far_lines = 1
vim.g.neovide_underline_stroke_scale = 1.0
vim.g.neovide_cursor_animation_length = 0.0
vim.g.neovide_cursor_trail_size = 0.0
vim.g.neovide_cursor_antialiasing = true
vim.g.neovide_cursor_animate_in_insert_mode = false
vim.g.neovide_cursor_animate_command_line = false
vim.g.neovide_cursor_smooth_blink = false
vim.g.neovide_cursor_vfx_mode = ""

vim.g.experimental_layer_grouping = true

-- mouse
vim.g.neovide_hide_mouse_when_typing = true

-- theme
vim.g.neovide_theme = "auto"

-- refresh rate
vim.g.neovide_refresh_rate = 144
vim.g.neovide_refresh_rate_idle = 1

-- idle
vim.g.neovide_no_idle = false

-- profiler
vim.g.neovide_profiler = false

return M
