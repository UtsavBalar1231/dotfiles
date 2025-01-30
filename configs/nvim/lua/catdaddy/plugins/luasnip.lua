return {
	"L3MON4D3/LuaSnip",
	enabled = not vim.g.vscode,
	lazy = true,
	config = function()
		-- vscode format
		require("luasnip.loaders.from_vscode").lazy_load()
		require("luasnip.loaders.from_vscode").lazy_load({ paths = { vim.fn.stdpath("config") .. "/snippets" } })
	end,
	opts = {
		history = true,
		delete_check_events = "TextChanged",
	},
}
