return {
	"catgoose/nvim-colorizer.lua",
	event = "InsertEnter",
	cmd = "HighlightColors",
	opts = {
		lazy_load = true,
		enable_named_colors = false,
		virtual_symbol = "󱓻",
		filetypes = { "*" },
		exclude_buffer = function()
			return vim.bo.filetype == "bigfile"
		end,
		user_default_options = {
			names = true, -- "Name" codes like Blue or blue
			names_custom = nil, -- Extra names to be highlighted: table|function|nil
			RGB = true, -- #RGB hex codes like #0FA or #1234FA
			RRGGBB = true, -- #RRGGBB hex codes like #00FF00
			RRGGBBAA = true, -- #RRGGBBAA hex codes like #00FF00AA
			AARRGGBB = true, -- #AARRGGBB hex codes like #FF11FFee
			rgb_fn = true, -- CSS rgb() and rgba() functions like rgb(0, 0, 255) or rgba(0, 0, 255, 0.5)
			hsl_fn = true, -- CSS hsl() and hsla() functions like hsl(120, 100%, 50%) or hsla(120, 100%, 50%, 0.5)
			css = true,
			mode = "background",
			sass = { enable = true, parsers = { "css" } },
			-- example use: cmp_menu, cmp_docs
			always_update = true,
		},
		buftypes = {},
		user_commands = true,
	},
}
