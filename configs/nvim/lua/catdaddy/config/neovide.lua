---@class neovide
local M = {}

-- vim.o.guifont = "JetBrainsMono Nerd Font:h16"

-- line spacing
vim.opt.linespace = 0

-- text gamma and contrast
vim.g.neovide_text_gamma = 0.0
vim.g.neovide_text_contrast = 0.5

-- padding
vim.g.neovide_padding_top = 4.0
vim.g.neovide_padding_bottom = 4.0
vim.g.neovide_padding_right = 4.0
vim.g.neovide_padding_left = 4.0

-- titlebar settings
vim.g.neovide_title_background_color = string.format(
    "%x",
    vim.api.nvim_get_hl(0, {id=vim.api.nvim_get_hl_id_by_name("Normal")}).bg
)
vim.g.neovide_title_text_color = "pink"
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
vim.g.neovide_opacity = 0.85
vim.g.neovide_normal_opacity = 0.90

-- animations
vim.g.neovide_position_animation_length = 0.0
vim.g.neovide_scroll_animation_length = 0.0
vim.g.neovide_scroll_animation_far_lines = 1
vim.g.neovide_hide_mouse_when_typing = false
vim.g.neovide_underline_stroke_scale = 1.0
vim.g.neovide_cursor_animation_length = 0.0
vim.g.neovide_cursor_trail_size = 0.0
vim.g.neovide_cursor_antialiasing = true
vim.g.neovide_cursor_animate_in_insert_mode = false
vim.g.neovide_cursor_animate_command_line = false
vim.g.neovide_cursor_smooth_blink = false
vim.g.neovide_cursor_vfx_mode = ""

-- theme
vim.g.neovide_theme = 'auto'

-- refresh rate
vim.g.neovide_refresh_rate = 144
vim.g.neovide_refresh_rate_idle = 1

-- idle
vim.g.neovide_no_idle = false

-- profiler
vim.g.neovide_profiler = false

return M
