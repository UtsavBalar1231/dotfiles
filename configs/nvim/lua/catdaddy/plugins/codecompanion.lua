vim.keymap.set({ "n", "v" }, "<C-a>", "<cmd>CodeCompanionActions<cr>", { noremap = true, silent = true })
vim.keymap.set({ "n", "v" }, "<leader>a", "<cmd>CodeCompanionChat Toggle<cr>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("v", "ga", "<cmd>CodeCompanionChat Add<cr>", { noremap = true, silent = true })

-- Expand 'cc' into 'CodeCompanion' in the command line
vim.cmd([[cab cc CodeCompanion]])

return {
	{
		"olimorris/codecompanion.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-treesitter/nvim-treesitter",
		},
		keys = {
			{ "<leader>aa", "<cmd>CodeCompanion<CR>", desc = "Inline" },
			{ "<leader>ac", "<cmd>CodeCompanionChat<CR>", desc = "Chat" },
		},
		opts = {
			opts = {
				log_level = "DEBUG",
			},
			display = {
				chat = {
					show_settings = true,
				},
			},
			strategies = {
				chat = {
					adapter = "copilot",
					keymaps = {
						completion = {
							modes = {
								i = "<C-x>",
							},
							index = 1,
							callback = "keymaps.completion",
							description = "Completion Menu",
						},
					},
				},
				inline = {
					adapter = "copilot",
				},
				agent = {
					adapter = "copilot",
				},
			},
			adapters = {
				copilot = function()
					return require("codecompanion.adapters").extend("copilot", {
					})
				end,
				--
				-- deepseek = function()
				-- 	return require("codecompanion.adapters").extend("deepseek", {
				-- 		env = {
				-- 			api_key = "DeepSeek_API_KEY", -- See note above about using cmd for secure API key storage
				-- 		},
				-- 		schema = {
				-- 			model = {
				-- 				default = "deepseek-reasoner",
				-- 			},
				-- 		},
				-- 	})
				-- end,
			},
		},
	},
}
