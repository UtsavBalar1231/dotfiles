return {
	"aliaksandr-trush/codeium.nvim",
	branch = "blink",
	event = "BufEnter",
	build = ":Codeium Auth",

	config = function()
		require("codeium").setup({
			enable_cmp_source = true,
			virtual_text = {
				enabled = true,
				manual = true,
				map_keys = true,
				key_bindings = {
					accept = "<C-space>",
					accept_word = "<C-y>",
					accept_line = "<C-g>",
					clear = "<C-x>",
					next = "<M-]>",
					prev = "<M-[>",
				},
			},
		})
	end,
}
