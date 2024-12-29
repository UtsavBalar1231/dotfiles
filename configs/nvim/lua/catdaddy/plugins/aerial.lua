return {
	{
		"stevearc/aerial.nvim",
		event = "VeryLazy",
		opts = function()
			local opts = {
				backends = { "lsp", "treesitter" },
				guides = {
					mid_item = "  ├",
					last_item = "  └",
					nested_top = "  │",
				},
				layout = {
					close_on_select = false,
					max_width = 35,
					min_width = 35,
				},
				show_guides = true,
				open_automatic = function(bufnr)
					local aerial = require("aerial")
					return vim.api.nvim_win_get_width(0) > 120
						and aerial.num_symbols(bufnr) > 0
						and not aerial.was_closed()
				end,
			}

			return opts
		end,
		config = function(_, opts)
			require("aerial").setup(opts)

			vim.keymap.set("n", "<F1>", "<cmd>AerialToggle<cr>", { silent = true })

			vim.api.nvim_set_hl(0, "AerialLine", { link = "PmenuSel" })
		end,
	},

	-- Telescope integration
	{
		"nvim-telescope/telescope.nvim",
		optional = true,
		opts = function()
			Util.on_load("telescope.nvim", function()
				require("telescope").load_extension("aerial")
			end)
		end,
		keys = {
			{
				"<leader>ss",
				"<cmd>Telescope aerial<cr>",
				desc = "Goto Symbol (Aerial)",
			},
		},
	},

	-- Lualine integration
	{
		"nvim-lualine/lualine.nvim",
		optional = true,
		opts = function(_, opts)
			if not vim.g.trouble_lualine then
				table.insert(opts.sections.lualine_c, {
					"aerial",
					sep = " ", -- separator between symbols
					sep_icon = " ", -- separator between icon and symbol

					-- The number of symbols to render top-down. In order to render only 'N' last
					-- symbols, negative numbers may be supplied. For instance, 'depth = -1' can
					-- be used in order to render only current symbol.
					depth = 5,

					-- When 'dense' mode is on, icons are not rendered near their symbols. Only
					-- a single icon that represents the kind of current symbol is rendered at
					-- the beginning of status line.
					dense = false,

					-- The separator to be used to separate symbols in dense mode.
					dense_sep = ".",

					-- Color the symbol icons.
					colored = true,
				})
			end
		end,
	},
}
