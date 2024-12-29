return {
	"akinsho/bufferline.nvim",
	event = "UIEnter",
	dependencies = "nvim-tree/nvim-web-devicons",
	keys = {
		{ "<leader>bp", "<Cmd>BufferLineTogglePin<CR>", desc = "Toggle Pin" },
		{ "<leader>bP", "<Cmd>BufferLineGroupClose ungrouped<CR>", desc = "Delete Non-Pinned Buffers" },
		{ "<leader>br", "<Cmd>BufferLineCloseRight<CR>", desc = "Delete Buffers to the Right" },
		{ "<leader>bl", "<Cmd>BufferLineCloseLeft<CR>", desc = "Delete Buffers to the Left" },
		{ "<S-left>", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev Buffer" },
		{ "<S-right>", "<cmd>BufferLineCycleNext<cr>", desc = "Next Buffer" },
		{ "[b", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev Buffer" },
		{ "]b", "<cmd>BufferLineCycleNext<cr>", desc = "Next Buffer" },
		{ "[B", "<cmd>BufferLineMovePrev<cr>", desc = "Move buffer prev" },
		{ "]B", "<cmd>BufferLineMoveNext<cr>", desc = "Move buffer next" },
	},
	options = {
		close_command = function(n)
			Snacks.bufdelete(n)
		end,
		right_mouse_command = function(n)
			Snacks.bufdelete(n)
		end,
		diagnostics = "nvim_lsp",
		always_show_bufferline = false,
		offsets = {
			{
				filetype = "neo-tree",
				text = "Neo-tree",
				highlight = "Directory",
				text_align = "left",
			},
		},
	},
	-- config = function(_, opts)
	-- 	if (vim.g.colors_name or ""):find("catppuccin") then
	-- 		opts.highlights = require("catppuccin.groups.integrations.bufferline").get()
	-- 	end
	--
	-- 	require("bufferline").setup(opts)
	-- end,
}
