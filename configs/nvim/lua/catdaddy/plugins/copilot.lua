return {
	{
		"zbirenbaum/copilot.lua",
		cmd = "Copilot",
		event = "InsertEnter",
		enabled = true,
		opts = {
			suggestion = {
				enabled = not vim.g.ai_cmp,
				auto_trigger = true,
				debounce = 75,
				keymap = {
					accept = "<C-g>",
					accept_word = false,
					accept_line = false,
					next = "<M-]>",
					prev = "<M-[>",
				},
			},
			panel = { enabled = false },
		},
	},
}
