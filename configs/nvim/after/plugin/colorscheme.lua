-- catppuccin: {{{
-- require("catppuccin").setup({
-- 	flavour = "mocha", -- latte, frappe, macchiato, mocha
-- 	background = {  -- :h background
-- 		light = "latte",
-- 		dark = "mocha",
-- 	},
-- 	transparent_background = false, -- disables setting the background color.
-- 	show_end_of_buffer = false,  -- shows the '~' characters after the end of buffers
-- 	term_colors = false,         -- sets terminal colors (e.g. `g:terminal_color_0`)
-- 	dim_inactive = {
-- 		enabled = true,
-- 		shade = "dark",
-- 		percentage = 0.15,
-- 	},
-- 	no_italic = false,     -- Force no italic
-- 	no_bold = false,       -- Force no bold
-- 	no_underline = false,  -- Force no underline
-- 	styles = {             -- Handles the styles of general hi groups (see `:h highlight-args`):
-- 		comments = { "italic" }, -- Change the style of comments
-- 		conditionals = { "italic" },
-- 		loops = {},
-- 		functions = {},
-- 		keywords = {},
-- 		strings = {},
-- 		variables = {},
-- 		numbers = {},
-- 		booleans = {},
-- 		properties = {},
-- 		types = {},
-- 		operators = {},
-- 	},
-- 	color_overrides = {
-- 		frappe = {
-- 			base = "#141414",
-- 		},
-- 		mocha = {
-- 			base = "#111111",
-- 		},
-- 	},
-- 	custom_highlights = {},
-- 	integrations = {
-- 		cmp = true,
-- 		gitsigns = true,
-- 		hop = true,
-- 		indent_blankline = {
-- 			colored_indent_levels = true,
-- 			enabled = true,
-- 		},
-- 		mason = false,
-- 		mini = false,
-- 		notify = false,
-- 		nvimtree = true,
-- 		telescope = {
-- 			enabled = true,
-- 		},
-- 		treesitter = true,
-- 		treesitter_context = false,
-- 	},
-- })
-- }}}

-- kanagawa: {{{
-- require("kanagawa").setup({
-- 	compile = false, -- enable compiling the colorscheme
-- 	undercurl = true, -- enable undercurls
-- 	commentStyle = { italic = true },
-- 	functionStyle = {},
-- 	keywordStyle = { italic = true },
-- 	statementStyle = { bold = true },
-- 	typeStyle = {},
-- 	transparent = true,
-- 	dimInactive = true,
-- 	terminalColors = true, -- define vim.g.terminal_color_{0,17}
-- 	colors = {
-- 		palette = {},
-- 		theme = { wave = {}, lotus = {}, dragon = {}, all = {} },
-- 	},
-- 	overrides = function(colors)
-- 		local theme = colors.theme
-- 		return {
-- 			NormalFloat = { bg = "none" },
-- 			FloatBorder = { bg = "none" },
-- 			FloatTitle = { bg = "none" },
--
-- 			-- Save an hlgroup with dark background and dimmed foreground
-- 			-- so that you can use it where your still want darker windows.
-- 			-- E.g.: autocmd TermOpen * setlocal winhighlight=Normal:NormalDark
-- 			NormalDark = { fg = theme.ui.fg_dim, bg = theme.ui.bg_m3 },
--
-- 			-- Popular plugins that open floats will link to NormalFloat by default;
-- 			-- set their background accordingly if you wish to keep them dark and borderless
-- 			LazyNormal = { bg = theme.ui.bg_m3, fg = theme.ui.fg_dim },
-- 			MasonNormal = { bg = theme.ui.bg_m3, fg = theme.ui.fg_dim },
-- 			Pmenu = { fg = theme.ui.shade0, bg = theme.ui.bg_p1 },
-- 			PmenuSel = { fg = "NONE", bg = theme.ui.bg_p2 },
-- 			PmenuSbar = { bg = theme.ui.bg_m1 },
-- 			PmenuThumb = { bg = theme.ui.bg_p2 },
-- 			TelescopeTitle = { fg = theme.ui.special, bold = true },
-- 			TelescopePromptNormal = { bg = theme.ui.bg_p1 },
-- 			TelescopePromptBorder = { fg = theme.ui.bg_p1, bg = theme.ui.bg_p1 },
-- 			TelescopeResultsNormal = { fg = theme.ui.fg_dim, bg = theme.ui.bg_m1 },
-- 			TelescopeResultsBorder = { fg = theme.ui.bg_m1, bg = theme.ui.bg_m1 },
-- 			TelescopePreviewNormal = { bg = theme.ui.bg_dim },
-- 			TelescopePreviewBorder = { bg = theme.ui.bg_dim, fg = theme.ui.bg_dim },
-- 		}
-- 	end,
-- 	theme = "dragon",
-- 	background = {
-- 		dark = "dragon",
-- 		light = "lotus",
-- 	},
-- })
-- }}}

-- gruvbox: {{{
local status_ok, gruvbox = pcall(require, "gruvbox")

if not status_ok then
	vim.notify("Missing gruvbox theme plugin", vim.log.levels.WARNING)
	return
end

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
		dark0 = "#1d2021",
		dark1 = "#282828",
		dark2 = "#3c3836",
		dark3 = "#504945",
		dark4 = "#665c54",
		dark5 = "#7c6f64",
	},
	overrides = {
		IndentBlanklineChar = { link = "GruvboxBg3" },
		IndentBlanklineSpaceChar = { link = "GruvboxBg3" },
		IndentBlanklineSpaceCharBlankline = { link = "GruvboxBg3" },
		IndentBlanklineContextChar = { link = "GruvboxGray" },
		["@lsp.type.method"] = { bg = "#49503b" },
        ["@comment.lua"] = { bg = "#000000" },
	},
	dim_inactive = true,
	transparent_mode = false,
})
-- }}}

vim.cmd.colorscheme("gruvbox")

-- Set background to dark
vim.opt.background = "dark"
