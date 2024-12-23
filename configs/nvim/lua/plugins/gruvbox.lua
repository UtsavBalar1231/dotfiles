return {
	"ellisonleao/gruvbox.nvim",
	priority = 1000,
	lazy = false,
	config = function()
		local gruvbox = require("gruvbox")

		gruvbox.setup({
			terminal_colors = true,
			undercurl = true,
			underline = true,
			bold = true,
			italic = {
				strings = true,
				emphasis = true,
				comments = true,
				operators = false,
				folds = true,
			},
			strikethrough = true,
			invert_selection = false,
			invert_signs = false,
			invert_tabline = false,
			invert_intend_guides = false,
			inverse = true,
			contrast = "hard",
			palette_overrides = {
				dark0_hard = "#000000",
				dark0 = "#141617",
			},
			overrides = {},
			dim_inactive = false,
			transparent_mode = false,
		})
		vim.cmd([[colorscheme gruvbox]])
	end,
}
