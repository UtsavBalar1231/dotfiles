return {
	"nvim-treesitter/nvim-treesitter",
	event = { "BufReadPost", "BufNewFile", "BufWritePre", "VeryLazy" },
	lazy = vim.fn.argc(-1) == 0, -- load treesitter early when opening a file from the cmdline
	init = function(plugin)
		-- PERF: add nvim-treesitter queries to the rtp and it's custom query predicates early
		-- This is needed because a bunch of plugins no longer `require("nvim-treesitter")`, which
		-- no longer trigger the **nvim-treesitter** module to be loaded in time.
		-- Luckily, the only things that those plugins need are the custom queries, which we make available
		-- during startup.
		require("lazy.core.loader").add_to_rtp(plugin)
		require("nvim-treesitter.query_predicates")
	end,
	cmd = { "TSUpdateSync", "TSUpdate", "TSInstall" },
	build = ":TSUpdate",
	dependencies = {
		"nvim-treesitter/nvim-treesitter-textobjects",
		"JoosepAlviste/nvim-ts-context-commentstring",
		"windwp/nvim-ts-autotag",
	},
	config = function()
		local configs = require("nvim-treesitter.configs")
		vim.filetype.add({
			extension = {
				c3 = "c3",
				c3i = "c3",
				c3t = "c3",
			},
		})

		local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
		parser_config.c3 = {
			install_info = {
				url = "https://github.com/c3lang/tree-sitter-c3",
				files = { "src/parser.c", "src/scanner.c" },
				branch = "main",
			},
		}
		configs.setup({
			matchup = {
				enable = true,
				disable = { "latex" },
			},
			auto_install = true,
			ensure_installed = {
				"bash",
				"c",
				"cpp",
				"devicetree",
				"gitcommit",
				"gitignore",
				"go",
				"html",
				"javascript",
				"json",
				"kconfig",
				"latex",
				"lua",
				"markdown",
				"markdown_inline",
				"meson",
				"ninja",
				"python",
				"query",
				"rust",
				"toml",
				"vim",
				"vimdoc",
				"yaml",
			},
			sync_install = false,
			highlight = {
				enable = true,
				use_languagetree = true,
				additional_vim_regex_highlighting = false,
			},
			ignore_install = {}, -- List of parsers to ignore installing
			endwise = { enable = true },
			autotag = { enable = true },
			indent = {
				enable = true,
			},
			incremental_selection = {
				enable = true,
				keymaps = {
					init_selection = "<CR>",
					scope_incremental = "<CR>",
					node_incremental = "<Tab>",
					node_decremental = "<S-Tab>",
				},
			},
			playground = {
				enable = true,
			},
			query_linter = {
				enable = true,
				use_virtual_text = true,
				lint_events = { "BufWrite", "CursorHold" },
			},
			refactor = {
				smart_rename = {
					enable = true,
					keymaps = {
						smart_rename = "grr",
					},
				},
			},
			textobjects = {
				select = {
					enable = true,

					-- Automatically jump forward to textobj, similar to targets.vim
					lookahead = true,

					keymaps = {
						-- You can use the capture groups defined in textobjects.scm
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
					set_jumps = true, -- whether to set jumps in the jumplist
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
						["<leader>a"] = "@parameter.inner",
					},
					swap_previous = {
						["<leader>A"] = "@parameter.inner",
					},
				},
			},
		})
	end,
}
