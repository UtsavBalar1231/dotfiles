---@diagnostic disable: inject-field, undefined-field, unused-local
return {
	{
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
					dark0_soft = "#1d2021",
					dark1 = "#141617",
					dark2 = "#1d2021",
					dark3 = "#282828",
					dark4 = "#3c3836",
					gray = "#504945",
				},
				overrides = {},
				dim_inactive = false,
				transparent_mode = false,
			})
			vim.cmd([[colorscheme gruvbox]])
		end,
	},
	{
		"rose-pine/neovim",
		name = "rose-pine",
		lazy = false,
		priority = 1000,
		opts = {
			variant = "main", -- auto, main, moon, or dawn
			dark_variant = "main", -- main, moon, or dawn
			dim_inactive_windows = false,
			extend_background_behind_borders = true,

			enable = {
				terminal = true,
				legacy_highlights = true,
				migrations = true,
			},

			styles = {
				bold = true,
				italic = true,
				transparency = false,
			},

			groups = {
				border = "muted",
				link = "iris",
				panel = "surface",

				error = "love",
				hint = "iris",
				info = "foam",
				note = "pine",
				todo = "rose",
				warn = "gold",

				git_add = "foam",
				git_change = "rose",
				git_delete = "love",
				git_dirty = "rose",
				git_ignore = "muted",
				git_merge = "iris",
				git_rename = "pine",
				git_stage = "iris",
				git_text = "rose",
				git_untracked = "subtle",

				h1 = "iris",
				h2 = "foam",
				h3 = "rose",
				h4 = "gold",
				h5 = "pine",
				h6 = "foam",
			},

			palette = {
				-- Override the builtin palette per variant
				main = {
					_nc = "#000000",
					base = "#000000",
					surface = "#16141f",
				},
			},

			highlight_groups = {
				-- Comment = { fg = "foam" },
				-- VertSplit = { fg = "muted", bg = "muted" },
			},

			before_highlight = function(group, highlight, palette)
				-- Disable all undercurls
				-- if highlight.undercurl then
				--     highlight.undercurl = false
				-- end
				--
				-- Change palette colour
				if highlight.fg == palette.pine then
					highlight.fg = palette.foam
				end
			end,
		},
	},
	{
		"catppuccin/nvim",
		name = "catppuccin",
		priority = 1000,
		lazy = false,
		opts = {
			no_italic = true,
			term_colors = true,
			transparent_background = false,
			styles = {
				comments = {},
				conditionals = {},
				loops = {},
				functions = {},
				keywords = {},
				strings = {},
				variables = {},
				numbers = {},
				booleans = {},
				properties = {},
				types = {},
			},
			color_overrides = {
				mocha = {
					base = "#000000",
					mantle = "#000000",
					crust = "#000000",
				},
			},
			integrations = {
				telescope = {
					enabled = true,
					style = "nvchad",
				},
				dropbar = {
					enabled = true,
					color_mode = true,
				},
			},
		},
	},
	{
		"miikanissi/modus-themes.nvim",
		lazy = false,
		priority = 1000,
		opts = {
			style = "modus_vivendi", -- `auto`, ``modus_operandi` and `modus_vivendi`
			variant = "default", -- `default`, `tinted`, `deuteranopia`, and `tritanopia`
			transparent = false,
			dim_inactive = false,
			hide_inactive_statusline = true, -- Hide statuslines on inactive windows. Works with the standard **StatusLine**, **LuaLine** and **mini.statusline**
			styles = {
				-- Style to be applied to different syntax groups
				-- Value is any valid attr-list value for `:help nvim_set_hl`
				comments = { italic = true },
				keywords = { italic = true },
				functions = {},
				variables = {},
			},

			---@param colors ColorScheme
			on_colors = function(colors)
				colors.error = colors.red_faint
			end,

			---@param highlights Highlights
			---@param colors ColorScheme
			on_highlights = function(highlights, colors)
				highlights.Boolean = { fg = colors.green }
			end,
		},
	},
	{
		"rebelot/kanagawa.nvim",
		lazy = false,
		priority = 1000,
		opts = {
			compile = false,
			undercurl = true,
			commentStyle = { italic = true },
			functionStyle = {},
			keywordStyle = { italic = true },
			statementStyle = { bold = true },
			typeStyle = {},
			transparent = false,
			dimInactive = false,
			terminalColors = true,
			colors = {
				palette = {
					dragonBlack3 = "#000000",
					dragonBlack4 = "#12120f",

					sumiInk3 = "#000000",
					sumiInk4 = "#14161D",

					waveBlue1 = "#0e151f",
    				waveBlue2 = "#0d181f",
				},
				theme = { wave = {}, lotus = {}, dragon = {}, all = {} },
			},
			theme = "dragon", -- wave, lotus, dragon
			background = {
				dark = "dragos",
				light = "lotus",
			},
		},
	},
	{
		"neanias/everforest-nvim",
		version = false,
		lazy = false,
		priority = 1000,
		config = function()
			require("everforest").setup({
				background = "hard", -- hard, medium, soft
				italics = true,
				diagnostic_virtual_text = "coloured",
				show_eob = true,
				float_style = "dim",
				inlay_hints_background = "dimmed",
				colours_override = function(palette)
					palette.bg0 = "#000000"
					palette.bg1 = "#070604"
					palette.bg2 = "#171614"
					palette.bg3 = "#272e33"
					palette.bg4 = "#2e383c"
					palette.bg5 = "#374145"
					palette.bg_dim = "#141617"
				end,
			})
		end,
	},
}
