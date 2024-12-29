return {
	"onsails/lspkind.nvim",
	event = "InsertEnter",
	opts = {
		require("lspkind").init({
			symbol_map = {
				Codeium = "{…}",
				Copilot = "",
			},
		}),
	},
}
