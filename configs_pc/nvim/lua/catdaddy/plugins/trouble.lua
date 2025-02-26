return {
	"folke/trouble.nvim",
	opts = {
		focus = true,
		win = { position = "top", size = 0.35 },

		vim.api.nvim_create_autocmd("QuickFixCmdPost", {
			callback = function()
				vim.cmd([[Trouble qflist open]])
			end,
		}),
	},
	cmd = "Trouble",
	event = "CmdlineEnter",
	keys = {
		{
			"<leader>cx",
			"<cmd>Trouble diagnostics toggle<cr>",
			desc = "Diagnostics (Trouble)",
		},
		{
			"<leader>cX",
			"<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
			desc = "Buffer Diagnostics (Trouble)",
		},
		{
			"<leader>cs",
			"<cmd>Trouble symbols toggle<cr>",
			desc = "Symbols (Trouble)",
		},
		{
			"<leader>cl",
			"<cmd>Trouble lsp toggle<cr>",
			desc = "LSP Definitions / references / ... (Trouble)",
		},
		{
			"<leader>cL",
			"<cmd>Trouble loclist toggle<cr>",
			desc = "Location List (Trouble)",
		},
		{
			"<leader>cQ",
			"<cmd>Trouble qflist toggle<cr>",
			desc = "Quickfix List (Trouble)",
		},
	},
}
