return {
	"CopilotC-Nvim/CopilotChat.nvim",
	event = "VeryLazy",
	dependencies = {
		{ "zbirenbaum/copilot.lua" },
		{ "nvim-lua/plenary.nvim" },
	},
	build = "make tiktoken", -- Only on MacOS or Linux
	opts = {},
	-- See Commands section for default commands if you want to lazy load on them
}
