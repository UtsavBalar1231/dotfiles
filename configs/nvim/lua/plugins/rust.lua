return {
	"rust-lang/rust.vim",
	ft = "rust",
	event = { "BufReadPre", "BufNewFile" },
	init = function()
		vim.g.rustfmt_autosave = 1
	end,
}
