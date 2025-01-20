return {
	{
		"zbirenbaum/copilot.lua",
		cmd = "Copilot",
		event = "InsertEnter",
		enabled = true,
		-- build = ":Copilot auth",
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
}
