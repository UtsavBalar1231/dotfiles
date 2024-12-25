return {
	"zbirenbaum/copilot.lua",
	cmd = "Copilot",
	event = "InsertEnter",
	opts = {
		suggestion = { enabled = true, auto_trigger = true, keymap = { accept = "<C-g>" } },
		panel = { enabled = false },
		vim.api.nvim_create_autocmd("User", {
			pattern = "BlinkCmpCompletionMenuOpen",
			callback = function()
				require("copilot.suggestion").dismiss()
				vim.b.copilot_suggestion_hidden = true
			end,
		}),

		vim.api.nvim_create_autocmd("User", {
			pattern = "BlinkCmpCompletionMenuClose",
			callback = function()
				vim.b.copilot_suggestion_hidden = false
			end,
		}),
	},
}
