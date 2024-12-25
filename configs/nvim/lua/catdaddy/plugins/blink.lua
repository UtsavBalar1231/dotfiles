local function get_lsp_completion_context(completion)
	local ok, source_name = pcall(function()
		return vim.lsp.get_client_by_id(completion.client_id).name
	end)

	if not ok then
		return nil
	end

	if source_name == "ts_ls" then
		return completion.detail
	elseif source_name == "pyright" and completion.labelDetails ~= nil then
		return completion.labelDetails.description
	elseif source_name == "texlab" then
		return completion.detail
	elseif source_name == "clangd" then
		local doc = completion.documentation
		if doc == nil then
			return
		end
		local import_str = doc.value
		import_str = import_str:gsub("[\n]+", "")

		local str
		str = import_str:match("<(.-)>")
		if str then
			return "<" .. str .. ">"
		end

		str = import_str:match("[\"'](.-)[\"']")
		if str then
			return '"' .. str .. '"'
		end

		return nil
	end
end

return {
	"saghen/blink.cmp",
	version = "*",
	event = "InsertEnter",
	build = "cargo build --release",
	lazy = false,
	dependencies = {
		"rafamadriz/friendly-snippets",
		"L3MON4D3/LuaSnip",
		-- "giuxtaposition/blink-cmp-copilot",
		"onsails/lspkind.nvim",
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
			-- default = { "lsp", "path", "snippets", "luasnip", "buffer", "copilot" },
			default = { "lsp", "path", "snippets", "luasnip", "buffer", "codeium" },
			providers = {
				-- copilot = {
				-- 	name = "copilot",
				-- 	enabled = true,
				-- 	module = "blink-cmp-copilot",
				-- 	score_offset = 800,
				-- 	async = true,
				-- 	max_items = 1,
				-- 	transform_items = function(_, items)
				-- 		local CompletionItemKind = require("blink.cmp.types").CompletionItemKind
				-- 		local kind_idx = #CompletionItemKind + 1
				-- 		CompletionItemKind[kind_idx] = "Copilot"
				-- 		for _, item in ipairs(items) do
				-- 			item.kind = kind_idx
				-- 		end
				-- 		return items
				-- 	end,
				-- },
				codeium = {
					name = "Codeium",
					module = "codeium.blink",
					async = true,
					enabled = true,
					score_offset = 1200,
					max_items = 1,
				},
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
					fallbacks = { "luasnip", "snippets", "buffer" },
					score_offset = 1000,
				},
				path = {
					name = "Path",
					module = "blink.cmp.sources.path",
					enabled = true,
					score_offset = 650,
					fallbacks = { "luasnip", "snippets", "buffer" },
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
					enabled = true,
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
					return cmp.select_next()
				end,
				"snippet_forward",
				"fallback",
			},
			["<S-Tab>"] = {
				function(cmp)
					return cmp.select_prev()
				end,
				"snippet_backward",
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
			accept = { auto_brackets = { enabled = false } },
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
				-- auto_show = function(ctx)
				-- 	return ctx.mode ~= "cmdline"
				-- end,
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
							ellipsis = false,
							text = function(ctx)
								return require("lspkind").symbolic(ctx.kind, {
									mode = "symbol",
								})
							end,
							highlight = function(ctx)
								return "BlinkCmpKind" .. ctx.kind
							end,
						},
						label = {
							width = {
								fill = true,
								max = 60,
							},
							text = function(ctx)
								return ctx.label .. ctx.label_detail
							end,
							highlight = function(ctx)
								local highlights = {
									{
										0,
										#ctx.label,
										group = ctx.deprecated and "BlinkCmpLabelDeprecated" or "BlinkCmpLabel",
									},
								}
								if ctx.label_detail then
									table.insert(highlights, {
										#ctx.label,
										#ctx.label + #ctx.label_detail,
										group = "BlinkCmpLabelDetail",
									})
								end

								for _, idx in ipairs(ctx.label_matched_indices) do
									table.insert(highlights, { idx, idx + 1, group = "BlinkCmpLabelMatch" })
								end

								return highlights
							end,
						},
						label_description = {
							width = { fill = true },
							text = function(ctx)
								return get_lsp_completion_context(ctx.item)
							end,
							highlight = "BlinkCmpLabelDescription",
						},
					},
				},
			},
		},
		appearance = { nerd_font_variant = "mono" },
	},
	opts_extend = { "sources.default" },
}
