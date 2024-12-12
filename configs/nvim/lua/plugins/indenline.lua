return {
	"lukas-reineke/indent-blankline.nvim",
	main = "ibl",

	config = function()
		local ibl = require("ibl")

		ibl.setup({
			scope = { enabled = false },

			exclude = {
				buftypes = {
					"nofile",
					"prompt",
					"quickfix",
					"terminal",
				},
				filetypes = {
					"aerial",
					"alpha",
					"dashboard",
					"help",
					"lazy",
					"mason",
					"neo-tree",
					"NvimTree",
					"neogitstatus",
					"notify",
					"startify",
					"toggleterm",
					"Trouble",
				},
			},
		})
	end,
}