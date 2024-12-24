return {
	"zbirenbaum/copilot.lua",
	cmd = "Copilot",
	event = "VeryLazy",
	opts = {
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
		panel = {
			enabled = false,
			auto_refresh = false,
			keymap = {
				jump_prev = "[[",
				jump_next = "]]",
				accept = "<CR>",
				refresh = "<C-r>",
				open = "<M-CR>",
			},
			layout = {
				position = "bottom", -- | top | left | right | horizontal | vertical
				ratio = 0.4,
			},
		},
		suggestion = {
			enabled = true,
			auto_trigger = true,
			hide_during_completion = true,
			debounce = 50,
			keymap = {
				accept = "<C-g>",
				accept_word = false,
				accept_line = false,
				next = "<M-]>",
				prev = "<M-[>",
				dismiss = "<C-e>",
			},
		},
		filetypes = {
			["*"] = true,
		},
		copilot_node_command = "node",
		server_opts_overrides = {},
	},
}
