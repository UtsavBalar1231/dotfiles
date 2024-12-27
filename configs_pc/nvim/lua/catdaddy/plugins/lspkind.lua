return {
	"onsails/lspkind.nvim",
	lazy = "false",
	opts = {
		require("lspkind").init({
			mode = "symbol",
			symbol_map = {
				Codeium = "{…}",
				Copilot = "",
			},
		}),
	},
}
