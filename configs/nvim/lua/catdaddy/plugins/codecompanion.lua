vim.keymap.set(
	{ "n", "v" },
	"<leader>aa",
	"<cmd>CodeCompanionActions<cr>",
	{ noremap = true, silent = true, desc = "AI: Open AI actions" }
)
vim.keymap.set(
	{ "n", "v" },
	"<leader>act",
	"<cmd>CodeCompanionChat Toggle<cr>",
	{ noremap = true, silent = true, desc = "AI: Toggle AI Chat" }
)
vim.keymap.set(
	"v",
	"<leader>aca",
	"<cmd>CodeCompanionChat Add<cr>",
	{ noremap = true, silent = true, desc = "AI: Chat continue" }
)
vim.keymap.set(
	{ "n", "v" },
	"<leader>ai",
	"<cmd>CodeCompanion<CR>",
	{ noremap = true, silent = true, desc = "AI: Inline chat" }
)
vim.keymap.set(
	{ "n", "v" },
	"<leader>ac",
	"<cmd>CodeCompanionChat<CR>",
	{ noremap = true, silent = true, desc = "AI: Chat" }
)

-- Expand 'cc' into 'CodeCompanion' in the command line
vim.cmd([[cab cc CodeCompanion]])

return {
	{
		"olimorris/codecompanion.nvim",
		event = "VeryLazy",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-treesitter/nvim-treesitter",
			{
				"MeanderingProgrammer/render-markdown.nvim",
				ft = { "markdown", "codecompanion" },
			},
		},
		opts = {
			opts = {
				log_level = "ERROR",
			},
			display = {
				chat = {
					show_settings = false,
				},
			},
			strategies = {
				chat = {
					adapter = "copilot",
					keymaps = {
						send = {
							modes = { n = "<C-s>", i = "<C-s>" },
						},
						close = {
							modes = { n = "<C-c>", i = "<C-c>" },
						},
						completion = {
							modes = {
								i = "<C-x>",
							},
							index = 1,
							callback = "keymaps.completion",
							description = "Completion Menu",
						},
					},
					slash_commands = {
						["file"] = {
							callback = "strategies.chat.slash_commands.file",
							description = "Select a file using Snacks",
							opts = {
								provider = "snacks",
								contains_code = true,
							},
						},
					},
				},
				inline = {
					adapter = "copilot",
					keymaps = {
						accept_change = {
							modes = { n = "ga" },
							description = "Accept the suggested change",
						},
						reject_change = {
							modes = { n = "gr" },
							description = "Reject the suggested change",
						},
					},
				},
				agent = {
					adapter = "copilot",
				},
			},
			adapters = {
				copilot = function()
					return require("codecompanion.adapters").extend("copilot", {
						schema = {
							max_tokens = {
								default = 16384,
							},
						},
					})
				end,
			},
		},
	},
}
