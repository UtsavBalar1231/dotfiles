return {
	"akinsho/bufferline.nvim",
	version = "*",
	event = "BufEnter",
	dependencies = 'nvim-tree/nvim-web-devicons',
	config = function()
		require("bufferline").setup({
		})
	end
}
