vim.api.nvim_create_autocmd("User", {
	pattern = "BlinkCmpMenuOpen",
	callback = function()
		require("copilot.suggestion").dismiss()
		vim.b.copilot_suggestion_hidden = true
	end,
})

vim.api.nvim_create_autocmd("User", {
	pattern = "BlinkCmpMenuClose",
	callback = function()
		vim.b.copilot_suggestion_hidden = false
	end,
})

return {
	"zbirenbaum/copilot.lua",
	cmd = "Copilot",
	event = "InsertEnter",
	opts = {
		filetypes = {
			markdown = true, -- Explicitly enable markdown
		},
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
}
