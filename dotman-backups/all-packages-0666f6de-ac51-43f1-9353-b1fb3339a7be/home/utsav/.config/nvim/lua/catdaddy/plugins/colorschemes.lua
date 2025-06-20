---@diagnostic disable: inject-field, undefined-field, unused-local
return {
	{
		"sainnhe/gruvbox-material",
		lazy = true,
		enabled = not vim.g.vscode,
		config = function()
			vim.g.gruvbox_material_background = "hard"
			vim.g.gruvbox_material_better_performance = 1
			vim.g.gruvbox_material_current_word = "bold"
			vim.g.gruvbox_material_cursor = "red"
			vim.g.gruvbox_material_diagnostic_line_highlight = 1
			-- vim.g.gruvbox_material_diagnostic_text_highlight = 1
			vim.g.gruvbox_material_diagnostic_virtual_text = "highlighted"
			vim.g.gruvbox_material_enable_bold = 1
			vim.g.gruvbox_material_enable_italic = 1
			vim.g.gruvbox_material_float_style = "dim"
			vim.g.gruvbox_material_foreground = "material"
			vim.g.gruvbox_material_inlay_hints_background = "dimmed"
			vim.g.gruvbox_material_menu_selection_background = "blue"
			vim.g.gruvbox_material_show_eob = 1
			vim.g.gruvbox_material_sign_column_background = "grey"
			vim.g.gruvbox_material_ui_contrast = "high"
			vim.g.gruvbox_material_visual = "green background"
			vim.cmd([[
				let g:gruvbox_material_colors_override = { 'bg_dim': ['#0e1010', '232'], 'bg0': ['#191817', '234'], 'bg1': ['#1d2021', '235'], 'bg2': ['#181615', '235'], 'bg3': ['#201d1b', '236'], 'bg4': ['#332e2a', '237'], 'bg5': ['#3e3732', '237'], 'grey0': ['#49413a', '243']}
				]])

			local configuration = vim.fn["gruvbox_material#get_configuration"]()
			local palette = vim.fn["gruvbox_material#get_palette"](
				configuration.background,
				configuration.foreground,
				configuration.colors_override
			)
			local highlights_groups = {
				FoldColumn = { bg = "none", fg = palette.grey0[1] },
				SignColumn = { bg = "none" },
				EndOfBuffer = { bg = "none", fg = palette.grey0[1] },
				Normal = { bg = "none", fg = palette.fg0[1] },
				NormalFloat = { bg = "none", fg = palette.fg0[1] },
				FloatBorder = { bg = "none" },
				FloatTitle = { bg = "none", fg = palette.orange[1] },
				TelescopeTitle = { bg = "none", fg = palette.fg0[1] },
				TelescopeBorder = { bg = "none", fg = palette.fg0[1] },
				TelescopeNormal = { fg = "none" },
				TelescopePromptNormal = { bg = "none", fg = palette.fg0[1] },
				TelescopeResultsNormal = { bg = "none", fg = palette.fg0[1] },
				TelescopeResultsDiffUntracked = { bg = "none", fg = palette.orange[1] },
				TelescopeSelection = { bg = palette.bg5[1], fg = palette.fg0[1] },
				TelescopePreviewDirectory = { fg = palette.red[1] },
				TelescopePromptCounter = { bg = "none", fg = palette.fg0[1] },
				TelescopeMatching = { bold = false, bg = "none", fg = palette.green[1] },
				Visual = { bg = palette.bg_visual_red[1] },
				ColorColumn = { bg = palette.bg_visual_blue[1] },
				CursorLine = { bg = palette.bg3[1], blend = 25 },
				GitSignsAdd = { bg = "none", fg = palette.green[1] },
				GitSignsChange = { bg = "none", fg = palette.yellow[1] },
				GitSignsDelete = { bg = "none", fg = palette.red[1] },
				DiffAdd = { bg = "none", fg = palette.green[1] },
				DiffChange = { bg = "none", fg = palette.yellow[1] },
				DiffDelete = { bg = "none", fg = palette.red[1] },
				DiffText = { bg = "none", fg = palette.blue[1] },
				LspInfoBorder = { bg = "none", fg = palette.fg0[1] },
				MatchParen = { bg = palette.grey2[1], fg = palette.bg0[1] },
				DiagnosticSignWarn = { bg = "none", fg = palette.yellow[1] },
				ErrorMsg = { fg = palette.red[1] },
			}

			for group, styles in pairs(highlights_groups) do
				vim.api.nvim_set_hl(0, group, styles)
			end
		end,
	},
	{
		"ellisonleao/gruvbox.nvim",
		lazy = true,
		enabled = not vim.g.vscode,
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
					dark0_hard = "#0e1010", -- Darken by 50%
					dark0_soft = "#191817", -- Darken by 50%
					dark0 = "#141414", -- Darken by 50%
					dark1 = "#181615", -- Darken by 60%
					dark2 = "#201d1b", -- Darken by 60%
					dark3 = "#332e2a", -- Darken by 50%
					dark4 = "#3e3732", -- Darken by 50%
					gray = "#49413a", -- Darken by 50%
				},
				overrides = {
					NonText = {
						fg = "#332e2a",
					},
				},
				dim_inactive = false,
				transparent_mode = false,
			})
		end,
	},
	{
		"rose-pine/neovim",
		name = "rose-pine",
		lazy = true,
		enabled = not vim.g.vscode,
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
		lazy = true,
		enabled = not vim.g.vscode,
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
					subtext1 = "#4a4d58",
					subtext0 = "#424550",
					overlay1 = "#32343e",
					overlay0 = "#2b2c35",
					surface2 = "#23242c",
					surface1 = "#1b1c24",
					surface0 = "#13141b",
					base = "#0c0c12",
					mantle = "#09090e",
					crust = "#06060a",
				},
			},
			integrations = {
				aerial = true,
				alpha = true,
				blink_cmp = true,
				cmp = true,
				dashboard = true,
				flash = true,
				fzf = true,
				grug_far = true,
				gitsigns = true,
				headlines = true,
				illuminate = true,
				indent_blankline = { enabled = true },
				leap = true,
				lsp_trouble = true,
				mason = true,
				markdown = true,
				mini = true,
				native_lsp = {
					enabled = true,
					underlines = {
						errors = { "undercurl" },
						hints = { "undercurl" },
						warnings = { "undercurl" },
						information = { "undercurl" },
					},
				},
				navic = { enabled = true, custom_bg = "lualine" },
				neotest = true,
				neotree = true,
				noice = true,
				notify = true,
				semantic_tokens = true,
				snacks = true,
				telescope = true,
				treesitter = true,
				treesitter_context = true,
				which_key = true,
			},
		},
	},
	{
		"rebelot/kanagawa.nvim",
		lazy = true,
		enabled = not vim.g.vscode,
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
				dark = "dragon",
				light = "lotus",
			},
		},
	},
	{
		"neanias/everforest-nvim",
		lazy = true,
		enabled = not vim.g.vscode,
		config = function()
			require("everforest").setup({
				background = "hard", -- hard, medium, soft
				italics = true,
				diagnostic_virtual_text = "coloured",
				show_eob = true,
				float_style = "dim",
				inlay_hints_background = "dimmed",
				colours_override = function(palette)
					palette.bg_dim = "#0c0e0f"
					palette.bg0 = "#0f1214"
					palette.bg1 = "#121618"
					palette.bg2 = "#161a1b"
					palette.bg3 = "#1a1e20"
					palette.bg4 = "#1d2022"
					palette.bg5 = "#2f3634"
				end,
				on_highlights = function(hl, palette)
					hl.NonText = { fg = palette.bg5 }
				end,
			})
		end,
	},
	{
		"AlexvZyl/nordic.nvim",
		lazy = true,
		enabled = not vim.g.vscode,
		config = function()
			require("nordic").setup({
				-- This callback can be used to override the colors used in the base palette.
				on_palette = function(palette)
					palette.black0 = "#1b1e26" -- 20% more dark of black2
					palette.black1 = "#0f1115" -- 50% more dark of black1
					palette.black2 = "#0c0e12" -- 50% more dark of black0
					palette.gray0 = "#121419" -- 50% more dark of gray0
					palette.gray1 = "#171a20" -- 50% more dark of gray1
					palette.gray2 = "#292e39" -- 30% more dark of gray2
					palette.gray3 = "#2e3541" -- 30% more dark of gray3
					palette.gray4 = "#444d5f" -- 10% more dark of gray4
					palette.gray5 = "#4c5b6e" -- 20% more dark of gray5
				end,
				-- This callback can be used to override the colors used in the extended palette.
				after_palette = function(palette)
					local U = require("nordic.utils")
					palette.bg_visual = U.blend(palette.orange.base, palette.bg, 0.20)
				end,
				on_highlight = function(highlights, palette) end,
				bold_keywords = true,
				italic_comments = true,
				transparent = {
					bg = false,
					float = false,
				},
				bright_border = true,
				reduced_blue = true,
				swap_backgrounds = false,
				cursorline = {
					bold = true,
					bold_number = true,
					theme = "dark",
					blend = 0.95,
				},
				noice = {
					style = "classic",
				},
				telescope = {
					style = "flat",
				},
				leap = {
					dim_backdrop = true,
				},
				ts_context = {
					dark_background = true,
				},
			})
		end,
	},
	{
		"folke/tokyonight.nvim",
		lazy = true,
		opts = { style = "moon" },
	},
}
