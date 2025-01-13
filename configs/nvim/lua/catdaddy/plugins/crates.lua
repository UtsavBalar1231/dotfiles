return {
	"saecki/crates.nvim",
	event = { "BufRead Cargo.toml" },
	enabled = not vim.g.vscode,
	config = function()
		require("crates").setup({
			lsp = {
				enabled = true,
				name = "crates.nvim",
				actions = true,
				completion = true,
				hover = true,
			},
			null_ls = {
				enabled = true,
				name = "crates.nvim",
			},
			cmp = {
				enabled = true,
				use_custom_kind = true,
				kind_text = {
					version = "Version",
					feature = "Feature",
				},
				kind_highlight = {
					version = "CmpItemKindVersion",
					feature = "CmpItemKindFeature",
				},
			},
		})
	end,
}
