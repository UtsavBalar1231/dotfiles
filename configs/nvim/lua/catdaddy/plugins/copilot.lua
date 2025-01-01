return {
	{
		"zbirenbaum/copilot.lua",
		cmd = "Copilot",
		event = "InsertEnter",
		build = ":Copilot auth",
		opts = {
			suggestion = {
				enabled = not vim.g.ai_cmp,
				auto_trigger = true,
				keymap = {
					accept = "<C-g>",
					next = "<M-]>",
					prev = "<M-[>",
				},
			},
			panel = { enabled = false },
		},
	},

	-- AI completion engine
	vim.g.ai_cmp
			and {
				"saghen/blink.cmp",
				optional = true,
				dependencies = { "giuxtaposition/blink-cmp-copilot" },
				opts = {
					sources = {
						default = { "copilot" },
						providers = {
							copilot = {
								name = "copilot",
								module = "blink-cmp-copilot",
								kind = "Copilot",
								score_offset = 100,
								async = true,

								transform_items = function(_, items)
									local CompletionItemKind = require("blink.cmp.types").CompletionItemKind
									local kind_idx = #CompletionItemKind + 1
									CompletionItemKind[kind_idx] = "Copilot"
									for _, item in ipairs(items) do
										item.kind = kind_idx
									end
									return items
								end,
							},
						},
					},
				},
			}
		or nil,
}
