local has_words_before = function()
	unpack = unpack or table.unpack
	local line, col = unpack(vim.api.nvim_win_get_cursor(0))
	return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
end

local function get_icon_provider()
	local mini_icons_avail, mini_icons = pcall(require, "mini.icons")
	if mini_icons_avail then
		return function(kind)
			return mini_icons.get("lsp", kind or "")
		end
	end
	local lspkind_avail, lspkind = pcall(require, "lspkind")
	if lspkind_avail then
		require("lspkind").init({
			mode = "symbol",
			symbol_map = {
				Codeium = "{…}",
				Copilot = "",
			},
		})
		return function(kind)
			return lspkind.symbolic(kind, { mode = "symbol" })
		end
	end
end

---@type function|false|nil
local icon_provider = false

---@param ctx table
local function get_icon(ctx)
	ctx.kind_hl_group = "BlinkCmpKind" .. ctx.kind
	if ctx.item.source_name == "LSP" then
		if icon_provider == false then
			icon_provider = get_icon_provider()
		end
		if icon_provider then
			local icon = icon_provider(ctx.kind)
			if icon then
				ctx.kind_icon = icon
			end
		end
	end
	return ctx
end

return {
	"saghen/blink.cmp",
	version = "*",
	enabled = not vim.g.vscode,
	event = "InsertEnter",
	build = "cargo build --release",

	dependencies = {
		"rafamadriz/friendly-snippets",
		"L3MON4D3/LuaSnip",
		"giuxtaposition/blink-cmp-copilot",
		-- "echasnovski/mini.icons",
		"onsails/lspkind.nvim",
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

		snippets = {
			preset = "luasnip",
		},

		appearance = {
			nerd_font_variant = "mono",
			use_nvim_cmp_as_default = true,
		},

		sources = {
			min_keyword_length = function(ctx)
				if ctx.mode == "cmdline" and string.find(ctx.line, " ") == nil then
					return 2
				end
				return 0
			end,
			default = function()
				local success, node = pcall(vim.treesitter.get_node)
				if
					success
					and node
					and vim.tbl_contains({ "comment", "line_comment", "block_comment" }, node:type())
				then
					return { "buffer" }
				else
					return { "lsp", "path", "snippets", "buffer" }
				end
			end,
			providers = {
				path = {
					opts = {
						trailing_slash = false,
						label_trailing_slash = true,
						get_cwd = function(context)
							return vim.fn.expand(("#%d:p:h"):format(context.bufnr))
						end,
						show_hidden_files_by_default = true,
					},
				},
			},
			cmdline = function()
				local type = vim.fn.getcmdtype()
				if type == "/" or type == "?" then
					return { "buffer" }
				end
				if type == ":" then
					return { "cmdline" }
				end
				return {}
			end,
		},

		signature = { enabled = true },

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
			},
			ghost_text = { enabled = true },
			menu = {
				auto_show = function(ctx)
					return ctx.mode ~= "cmdline" or not vim.tbl_contains({ "/", "?" }, vim.fn.getcmdtype())
				end,
				draw = {
					treesitter = { "lsp" },
					columns = {
						{ "kind_icon", "label", "label_description", gap = 1 },
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
						kind_icon = {
							text = function(ctx)
								get_icon(ctx)
								return ctx.kind_icon .. ctx.icon_gap
							end,
							highlight = function(ctx)
								return get_icon(ctx).kind_hl_group
							end,
						},
					},
				},
			},
		},
	},

	opts_extend = {
		"sources.cmdline",
		"sources.default",
	},
}
