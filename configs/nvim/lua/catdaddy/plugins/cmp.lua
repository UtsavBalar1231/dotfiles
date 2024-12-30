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

local function get_icon(ctx)
	ctx.kind_hl_group = "BlinkCmpKind" .. ctx.kind
	if ctx.item.source_name == "LSP" then
		local item_doc, color_item = ctx.item.documentation, nil
		if item_doc then
			local highlight_colors_avail, highlight_colors = pcall(require, "nvim-highlight-colors")
			color_item = highlight_colors_avail and highlight_colors.format(item_doc, { kind = ctx.kind })
		end
		if icon_provider == false then
			icon_provider = get_icon_provider()
		end
		if icon_provider then
			local icon = icon_provider(ctx.kind)
			if icon then
				ctx.kind_icon = icon
			end
		end
		if color_item and color_item.abbr and color_item.abbr_hl_group then
			ctx.kind_icon, ctx.kind_hl_group = color_item.abbr, color_item.abbr_hl_group
		end
	end
	return ctx
end

return {
	"saghen/blink.cmp",
	version = "*",
	event = "InsertEnter",
	build = "cargo build --release",
	dependencies = {
		"rafamadriz/friendly-snippets",
		"L3MON4D3/LuaSnip",
		"giuxtaposition/blink-cmp-copilot",
		"onsails/lspkind.nvim",
		"brenoprata10/nvim-highlight-colors",
	},

	opts = {
		snippets = {
			expand = function(snippet)
				require("luasnip").lsp_expand(snippet)
			end,
			active = function(filter)
				if filter and filter.direction then
					return require("luasnip").jumpable(filter.direction)
				end
				return require("luasnip").in_snippet()
			end,
			jump = function(direction)
				require("luasnip").jump(direction)
			end,
		},
		sources = {
			min_keyword_length = function(ctx)
				if ctx.mode == "cmdline" and string.find(ctx.line, " ") == nil then
					return 2
				end
				return 0
			end,
			default = { "lsp", "path", "snippets", "luasnip", "buffer" },
			providers = {
				buffer = {
					name = "buffer",
					enabled = true,
					max_items = 4,
					score_offset = 700,
				},
				luasnip = {
					name = "luasnip",
					enabled = true,
					module = "blink.cmp.sources.luasnip",
					score_offset = 900,
					max_items = 5,
				},
				lsp = {
					name = "LSP",
					enabled = true,
					module = "blink.cmp.sources.lsp",
					score_offset = 1000,
				},
				path = {
					name = "Path",
					module = "blink.cmp.sources.path",
					enabled = true,
					score_offset = 650,
					opts = {
						trailing_slash = false,
						label_trailing_slash = true,
						get_cwd = function(context)
							return vim.fn.expand(("#%d:p:h"):format(context.bufnr))
						end,
						show_hidden_files_by_default = true,
					},
					max_items = 3,
				},
				snippets = {
					name = "snippets",
					enabled = function(ctx)
						return ctx ~= nil
							and ctx.trigger.kind == vim.lsp.protocol.CompletionTriggerKind.TriggerCharacter
					end,
					module = "blink.cmp.sources.snippets",
					score_offset = 850,
					max_items = 5,
				},
			},
		},
		keymap = {
			["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
			["<C-e>"] = { "hide", "fallback" },
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
		signature = { enabled = true },
		completion = {
			accept = { auto_brackets = { enabled = true } },
			list = {
				selection = function(ctx)
					if ctx.mode == "cmdline" then
						return "manual"
					else
						return "manual"
					end
				end,
				cycle = { from_top = false },
				max_items = 50,
			},
			documentation = {
				window = {
					min_width = 15,
					max_width = 50,
					max_height = 15,
				},
				auto_show = true,
				auto_show_delay_ms = 250,
			},
			ghost_text = { enabled = true },
			menu = {
				draw = {
					align_to_component = "label",
					treesitter = { "lsp" },
					columns = {
						{ "label", "label_description", gap = 1 },
						{ "kind_icon", "kind", gap = 1 },
						{ "source_name", gap = 1 },
					},
					components = {
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
		appearance = {
			nerd_font_variant = "mono",
			use_nvim_cmp_as_default = false,
		},
	},
	opts_extend = {
		"sources.cmdline",
		"sources.default",
	},
}
