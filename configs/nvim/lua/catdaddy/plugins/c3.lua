return {
	"wstucco/c3.nvim",
	ft = "c3",
	enabled = not vim.g.vscode,
	config = function()
		require("c3")
	end,
}
