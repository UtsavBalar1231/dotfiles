return {
	"folke/trouble.nvim",
	cmd = "Trouble",
	event = "CmdlineEnter",
	opts = {
		-- focus = true,
		modes = {
			preview_float = {
				mode = "diagnostics",
				preview = {
					type = "float",
					relative = "editor",
					border = Util.config.icons.border,
					title = "Preview",
					title_pos = "center",
					position = { 0, -2 },
					size = { width = 0.3, height = 0.3 },
					zindex = 200,
				},
			},
		},
	},
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
	config = function()
		-- Automatically Open Trouble Quickfix
		vim.api.nvim_create_autocmd("QuickFixCmdPost", {
			callback = function()
				vim.cmd([[Trouble qflist open]])
			end,
		})
	end,
}
