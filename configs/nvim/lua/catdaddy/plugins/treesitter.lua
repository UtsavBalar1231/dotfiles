return {
	"nvim-treesitter/nvim-treesitter",
	event = { "BufReadPost", "BufNewFile" },
	cmd = { "TSInstall", "TSBufEnable", "TSBufDisable", "TSModuleInfo" },
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
