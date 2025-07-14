return {
	"mikesmithgh/kitty-scrollback.nvim",
	cmd = { "KittyScrollbackGenerateKittens", "KittyScrollbackCheckHealth" },
	event = { "User KittyScrollbackLaunch" },
	enabled = not vim.g.vscode,
	config = function()
		require("kitty-scrollback").setup()
	end,
}
