return {
	"lewis6991/gitsigns.nvim",
	event = { "BufReadPost", "BufNewFile", "BufWritePre" },
	config = function()
		require("gitsigns").setup({
			signs = {
				add = { text = "▎" },
				change = { text = "▎" },
				delete = { text = "" },
				topdelete = { text = "" },
				changedelete = { text = "▎" },
				untracked = { text = "▎" },
			},
			signs_staged = {
				add = { text = "▎" },
				change = { text = "▎" },
				delete = { text = "" },
				topdelete = { text = "" },
				changedelete = { text = "▎" },
			},
			signcolumn = true,
			numhl = true,
			linehl = false,
			word_diff = true,

			on_attach = function(bufnr)
				local gs = package.loaded.gitsigns

				local function map(mode, l, r, opts)
					opts = opts or {}
					opts.buffer = bufnr
					vim.keymap.set(mode, l, r, opts)
				end
				-- Navigation
				map("n", "<leader>g<Down>", function()
					if vim.wo.diff then
						return "<leader>g<Down>"
					end
					vim.schedule(function()
						gs.next_hunk()
					end)
					return "<Ignore>"
				end, { expr = true, desc = "git Next hunk" })

				map("n", "<leader>g<Up>", function()
					if vim.wo.diff then
						return "<leader>g<Up>"
					end
					vim.schedule(function()
						gs.prev_hunk()
					end)
					return "<Ignore>"
				end, { expr = true, desc = "git Previous hunk" })
				map("n", "<leader>gp", gs.preview_hunk, { desc = "git Preview hunk" })
				map("n", "<leader>gd", gs.diffthis, { desc = "git Diff this" })
				map("v", "<leader>hs", function()
					gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
				end, { desc = "git Stage hunk" })
				map("n", "<leader>gU", gs.undo_stage_hunk, { desc = "git Undo stage hunk" })
				map("n", "<leader>gS", gs.stage_buffer, { desc = "git Stage buffer" })
				map("n", "<leader>gR", gs.reset_buffer, { desc = "git Reset buffer" })
				map("n", "<leader>gu", function()
					gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
				end, { desc = "git Reset hunk" })
				map("n", "<leader>bl", function()
					gs.blame_line({ full = true })
				end, { desc = "git Blame line" })
				map("n", "<leader>tb", gs.toggle_current_line_blame, { desc = "git Toggle current line blame" })
				map("n", "<leader>hD", function()
					gs.diffthis("~")
				end, { desc = "git Diff this (against HEAD~)" })
				map("n", "<leader>td", gs.toggle_deleted, { desc = "git Toggle deleted" })
			end,
			preview_config = {
				border = Util.config.icons.border,
				style = "minimal",
				relative = "cursor",
				row = 0,
				col = 1,
			},
		})

		Snacks.toggle({
			name = "Git Signs",
			get = function()
				return require("gitsigns.config").config.signcolumn
			end,
			set = function(state)
				require("gitsigns").toggle_signs(state)
			end,
		}):map("<leader>uG")
	end,
}
