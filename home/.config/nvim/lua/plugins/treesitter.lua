return {
	{
		"nvim-treesitter/nvim-treesitter",
		opts = function(_, opts)
			-- Add c3 filetype
			vim.filetype.add({
				extension = {
					c3 = "c3",
					c3i = "c3",
					c3t = "c3",
				},
			})

			-- Extend ensure_installed list
			vim.list_extend(opts.ensure_installed, {
				"devicetree",
				"gitcommit",
				"gitignore",
				"go",
				"ini",
				"kconfig",
				"kdl",
				"latex",
				"make",
				"meson",
				"ninja",
				"rasi",
				"rust",
				"udev",
			})

			-- Enable indent
			opts.indent = opts.indent or {}
			opts.indent.enable = true

			-- Configure textobjects
			opts.textobjects = {
				select = {
					enable = true,
					lookahead = true,
					keymaps = {
						["af"] = "@function.outer",
						["if"] = "@function.inner",
						["ac"] = "@class.outer",
						["ic"] = "@class.inner",
						["ar"] = "@block.outer",
						["ir"] = "@block.inner",
					},
				},
				move = {
					enable = true,
					set_jumps = true,
					goto_next_start = {
						["]m"] = "@function.outer",
						["]]"] = "@class.outer",
					},
					goto_next_end = {
						["]M"] = "@function.outer",
						["]["] = "@class.outer",
					},
					goto_previous_start = {
						["[m"] = "@function.outer",
						["[["] = "@class.outer",
					},
					goto_previous_end = {
						["[M"] = "@function.outer",
						["[]"] = "@class.outer",
					},
				},
				swap = {
					enable = true,
					swap_next = {
						-- NOTE: <leader>a/<leader>A may conflict with sidekick's <leader>a* prefix
						["<leader>a"] = "@parameter.inner",
					},
					swap_previous = {
						["<leader>A"] = "@parameter.inner",
					},
				},
			}

			return opts
		end,
	},

	{
		"nvim-treesitter/nvim-treesitter-textobjects",
		branch = "main",
		dependencies = { "nvim-treesitter/nvim-treesitter" },
		event = "VeryLazy",
	},

	{
		"nvim-treesitter/nvim-treesitter-context",
		event = "LazyFile",
		enabled = not vim.g.vscode,
		opts = function()
			local tsc = require("treesitter-context")
			Snacks.toggle({
				name = "Treesitter Context",
				get = tsc.enabled,
				set = function(state)
					if state then
						tsc.enable()
					else
						tsc.disable()
					end
				end,
			}):map("<leader>ut")
			return {
				mode = "cursor",
				max_lines = 3,
				multiwindow = false,
				min_window_height = 0,
				multiline_threshold = 20,
			}
		end,
	},

	{
		"windwp/nvim-ts-autotag",
		event = "LazyFile",
		opts = {},
	},
}
