return {
	"zbirenbaum/copilot.lua",
	cmd = "Copilot",
	build = ":Copilot auth",
	event = "BufReadPost",
	opts = {
		suggestion = {
			enabled = true,
			auto_trigger = true,
			keymap = {
				accept = "<C-g>",
				next = "<M-]>",
				prev = "<M-[>",
			},
		},
		hide_during_completion = true,
		panel = { enabled = false },
		filetypes = {
			markdown = true,
			help = true,
		},
	},
}
