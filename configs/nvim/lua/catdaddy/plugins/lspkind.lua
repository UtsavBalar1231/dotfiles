return {
	"onsails/lspkind.nvim",
	opts = {
		require("lspkind").init({
			symbol_map = {
				Codeium = "{…}",
				Copilot = "",
			},
		}),
	},
}
