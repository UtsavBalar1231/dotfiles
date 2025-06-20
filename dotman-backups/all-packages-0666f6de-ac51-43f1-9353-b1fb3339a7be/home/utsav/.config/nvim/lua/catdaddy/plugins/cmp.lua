local has_words_before = function()
	unpack = unpack or table.unpack
	local line, col = unpack(vim.api.nvim_win_get_cursor(0))
	return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
end

return {
	"saghen/blink.cmp",
	version = "*",
	enabled = not vim.g.vscode,
	event = "InsertEnter",
	build = "cargo build --release",

	dependencies = {
		"L3MON4D3/LuaSnip",
		"xzbdmw/colorful-menu.nvim",
	},

	--- @module 'blink.cmp'
	--- @type blink.cmp.Config
	opts = {
		keymap = {
			preset = "none",
			["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
			["<C-e>"] = { "hide", "fallback" },
			["<C-y>"] = { "select_and_accept" },
			["<CR>"] = { "accept", "fallback" },

			["<Tab>"] = {
				function(cmp)
					if cmp.is_visible() then
						return cmp.select_next()
					elseif cmp.snippet_active({ direction = 1 }) then
						return cmp.snippet_forward()
					elseif has_words_before() then
						return cmp.show()
					end
				end,
				"fallback",
			},
			["<S-Tab>"] = {
				function(cmp)
					if cmp.is_visible() then
						return cmp.select_prev()
					elseif cmp.snippet_active({ direction = -1 }) then
						return cmp.snippet_backward()
					end
				end,
				"fallback",
			},

			["<Up>"] = { "select_prev", "fallback" },
			["<Down>"] = { "select_next", "fallback" },
			["<C-p>"] = { "select_prev", "fallback" },
			["<C-n>"] = { "select_next", "fallback" },
			["<C-up>"] = { "scroll_documentation_up", "fallback" },
			["<C-down>"] = { "scroll_documentation_down", "fallback" },
		},

		snippets = { preset = "luasnip" },

		signature = {
			enabled = true,
			-- window = { border = Util.config.icons.border },
		},

		appearance = {
			nerd_font_variant = "mono",
			use_nvim_cmp_as_default = false,
			kind_icons = Util.config.icons.kinds,
		},

		sources = {
			default = function()
				return { "buffer", "lsp", "path", "snippets" }
			end,
			providers = {
				cmdline = {
					-- ignores cmdline completions when executing shell commands
					enabled = function()
						return vim.fn.getcmdtype() ~= ":" or not vim.fn.getcmdline():match("^[%%0-9,'<>%-]*!")
					end,
				},
				buffer = {
					name = "Buffer",
					enabled = true,
					max_items = 3,
					module = "blink.cmp.sources.buffer",
					min_keyword_length = 3,
					score_offset = 100,
				},
				lsp = {
					name = "lsp",
					enabled = true,
					module = "blink.cmp.sources.lsp",
					min_keyword_length = 2,
					score_offset = 80,
				},
				path = {
					name = "Path",
					module = "blink.cmp.sources.path",
					score_offset = 25,
					fallbacks = { "snippets", "buffer" },
					opts = {
						get_cwd = function(context)
							-- return vim.fn.getcwd()
							return vim.fn.expand(("#%d:p:h"):format(context.bufnr))
						end,
						trailing_slash = false,
						show_hidden_files_by_default = true,
						label_trailing_slash = true,
					},
				},
			},
		},

		completion = {
			accept = { auto_brackets = { enabled = true } },
			list = {
				selection = {
					preselect = function(ctx)
						return ctx.mode ~= "cmdline"
					end,
					auto_insert = function(ctx)
						return ctx.mode ~= "cmdline"
					end,
				},
				cycle = { from_top = false },
				max_items = 50,
			},
			documentation = {
				auto_show = false,
				auto_show_delay_ms = 150,
				-- window = { border = Util.config.icons.border },
			},
			ghost_text = { enabled = true },
			menu = {
				auto_show = function(ctx)
					return ctx.mode ~= "cmdline" or not vim.tbl_contains({ "/", "?" }, vim.fn.getcmdtype())
				end,
				-- border = Util.config.icons.border,
				draw = {
					treesitter = { "lsp" },
					columns = {
						{ "kind_icon", "label", gap = 1 },
						{ "kind", "source_name", gap = 1 },
					},
					components = {
						label = {
							text = function(ctx)
								return require("colorful-menu").blink_components_text(ctx)
							end,
							highlight = function(ctx)
								return require("colorful-menu").blink_components_highlight(ctx)
							end,
						},
					},
				},
			},
		},
	},

	opts_extend = { "sources.default", "cmdline.sources", "term.sources" },
}
