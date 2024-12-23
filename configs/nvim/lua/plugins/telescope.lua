return {
	"nvim-telescope/telescope.nvim",
	event = { "BufReadPre", "BufNewFile" },
	cmd = "Telescope",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-telescope/telescope-file-browser.nvim",
		"nvim-telescope/telescope-ui-select.nvim",
		"nvim-telescope/telescope-frecency.nvim",
		{ "nvim-telescope/telescope-fzf-native.nvim", build = "make", lazy = true },
		"folke/trouble.nvim",
	},
	config = function()
		local telescope = require("telescope")
		local builtin = require("telescope.builtin")

		local function map(mode, key, action, desc)
			vim.keymap.set(mode, key, action, desc)
		end

		local function set_colorscheme(colorscheme)
			vim.cmd("colorscheme " .. colorscheme)
			local config_path = vim.fn.stdpath("config") .. "/colorscheme.lua"
			local file = io.open(config_path, "w")
			if file then
				file:write(string.format("vim.cmd('colorscheme %s')\n", colorscheme))
				file:close()
			else
				vim.notify("Failed to save colorscheme!", vim.log.levels.ERROR)
			end
			vim.notify("Colorscheme set to " .. colorscheme, vim.log.levels.INFO)
		end

		local function pick_colorscheme()
			local colorschemes = vim.fn.getcompletion("", "color")
			require("telescope.pickers")
				.new({}, {
					prompt_title = "Select Colorscheme",
					finder = require("telescope.finders").new_table({
						results = colorschemes,
					}),
					sorter = require("telescope.config").values.generic_sorter({}),
					attach_mappings = function(_, keymap)
						local actions = require("telescope.actions")
						local state = require("telescope.actions.state")

						-- Live preview of the colorscheme
						keymap("i", "<CR>", function(prompt_bufnr)
							local selection = state.get_selected_entry()
							actions.close(prompt_bufnr)
							set_colorscheme(selection.value)
						end)

						-- Preview the colorscheme while navigating
						keymap("i", "<C-p>", function()
							local selection = state.get_selected_entry()
							if selection then
								vim.cmd("colorscheme " .. selection.value)
							end
						end)

						keymap("n", "<CR>", function(prompt_bufnr)
							local selection = state.get_selected_entry()
							actions.close(prompt_bufnr)
							set_colorscheme(selection.value)
						end)

						-- Preview the colorscheme while navigating in normal mode
						keymap("n", "<C-p>", function()
							local selection = state.get_selected_entry()
							if selection then
								vim.cmd("colorscheme " .. selection.value)
							end
						end)

						return true
					end,

					-- Use `on_display` to preview colorscheme as you scroll
					on_display = function()
						local selection = require("telescope.actions.state").get_selected_entry()
						if selection then
							vim.cmd("colorscheme " .. selection.value)
						end
					end,
				})
				:find()
		end

		-- Keymap to invoke the picker
		vim.keymap.set("n", "<leader>cs", pick_colorscheme, { desc = "Pick and set colorscheme with preview" })
		-- Grep in current directory
		map("n", "<leader>fi", builtin.find_files, { desc = "Telescope find files" })
		map("n", "<leader>fg", builtin.live_grep, { desc = "Telescope live grep" })

		local function live_grep_pwd()
			builtin.live_grep({
				prompt_title = "Live grep in parent directory",
				cwd = vim.fn.fnamemodify(vim.fn.expand("%:p"), ":h"),
				hidden = true,
			})
		end

		-- Live Grep in parent directory of the current buffer
		map("n", "<leader>fG", live_grep_pwd, { desc = "Telescope live grep in parent directory" })
		map("n", "<leader>fb", builtin.buffers, { desc = "Telescope buffers" })
		map("n", "<leader>fo", builtin.oldfiles, { desc = "Telescope old files" })
		map("n", "<leader>f/", builtin.current_buffer_fuzzy_find, { desc = "Telescope current buffer fuzzy find" })
		map("n", "<leader>fe", builtin.diagnostics, { desc = "Telescope diagnostics" })
		map("n", "<leader>fq", builtin.quickfix, { desc = "Telescope quickfix list" })
		map("n", "<leader>fl", builtin.loclist, { desc = "Telescope loc list" })

		-- Map <leader>f[ to goto previous diagnostic
		map("n", "<leader>f[", function()
			vim.diagnostic.goto_prev({ desc = "Telescope diagnostics previous" })
		end, {})

		-- Map <leader>f] to goto next diagnostic
		map("n", "<leader>f]", function()
			vim.diagnostic.goto_next({ desc = "Telescope diagnostics next" })
		end, {})

		vim.api.nvim_create_autocmd("LspAttach", {
			callback = function()
				map("n", "<leader>fd", builtin.lsp_definitions, { desc = "Telescope lsp definitions" })
				map("n", "<leader>fr", builtin.lsp_references, { desc = "Telescope lsp references" })
				map(
					"n",
					"<leader>fw",
					builtin.lsp_dynamic_workspace_symbols,
					{ desc = "Telescope lsp dynamic workspace symbols" }
				)
			end,
		})

		-- git commands
		map("n", "<leader>gs", builtin.git_status, { desc = "Telescope git status" })
		map("n", "<leader>tb", builtin.git_branches, { desc = "Telescope git branches" })
		map("n", "<leader>tc", builtin.git_commits, { desc = "Telescope git commits" })
		map("n", "<leader>gC", builtin.git_bcommits, { desc = "Telescope git buffer commits" })
		map("n", "<leader>gf", builtin.git_files, { desc = "Telescope git files" })
		map("n", "<leader>gS", builtin.git_stash, { desc = "Telescope git stash files" })

		map("n", "<leader>fm", "<cmd>Telescope man_pages<cr>", { desc = "Telescope Man Pages" })
		map("n", "<leader>fk", "<cmd>Telescope keymaps<cr>", { desc = "Telescope Keymaps" })

		map("n", "<leader>ff", function()
			require("telescope").extensions.file_browser.file_browser()
		end)

		map("n", "<leader>fF", function()
			require("telescope").extensions.file_browser.file_browser({
				cwd = vim.fn.expand("%:p:h"),
			})
		end)

		local fb_actions = require("telescope").extensions.file_browser.actions
		local open_with_trouble = require("trouble.sources.telescope")

		telescope.setup({
			pickers = {
				find_files = {
					hidden = true,
					theme = "dropdown",
				},
			},
			defaults = {
				layout_strategy = "horizontal",
				layout_config = {
					horizontal = {
						prompt_position = "top",
						preview_width = function(_, cols, _)
							return math.floor(cols * 0.6)
						end,
					},
					width = function(_, cols, _)
						return math.floor(cols * 0.9)
					end,
					height = function(_, _, rows)
						return math.floor(rows * 0.85)
					end,
				},
				mappings = {
					i = {
						["<esc>"] = require("telescope.actions").close,
						["<c-t>"] = open_with_trouble,
						["<a-t>"] = open_with_trouble,
					},
					n = {
						["q"] = require("telescope.actions").close,
					},
				},
				find_command = {
					"rg",
					"--no-heading",
					"--with-filename",
					"--line-number",
					"--column",
					"--smart-case",
				},
				selection_caret = " ➤ ",
				prompt_prefix = "   ",
				entry_prefix = "  ",
				initial_mode = "normal",
				selection_strategy = "reset",
				sorting_strategy = "ascending",
				file_sorter = require("telescope.sorters").get_fuzzy_file,
				file_ignore_patterns = { "node_modules", "%.git/", "dist/", "build/", "%.lock" },
				generic_sorter = require("telescope.sorters").get_generic_fuzzy_sorter,
				path_display = {
					filename_first = {
						reverse_directories = true,
					},
				},
				winblend = 0,
				border = true,
				-- borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
				color_devicons = true,
				use_less = true,
				set_env = { ["COLORTERM"] = "truecolor", ["BAT_THEME"] = "gruvbox-dark" },
				file_previewer = require("telescope.previewers").cat.new,
				grep_previewer = require("telescope.previewers").vimgrep.new,
				qflist_previewer = require("telescope.previewers").qflist.new,
				-- Developer configurations: Not meant for general override
				buffer_previewer_maker = require("telescope.previewers").buffer_previewer_maker,
			},
			extensions = {
				wrap_results = true,
				fzf = {
					fuzzy = true,
					override_generic_sorter = true,
					override_file_sorter = true,
					case_mode = "smart_case",
				},
				["ui-select"] = {
					require("telescope.themes").get_cursor({}),
				},
				file_browser = {
					theme = "ivy",
					hijack_netrw = true,
					mappings = {
						["i"] = {
							["<C-w>"] = function()
								vim.cmd("normal vbd")
							end,
							["<C-h>"] = "which_key",
						},
						["n"] = {
							-- your custom normal mode mappings
							["N"] = fb_actions.create,
							["h"] = fb_actions.goto_parent_dir,
							["/"] = function()
								vim.cmd("startinsert")
							end,
						},
					},
					hide_dotfiles = false,
					show_hidden = true,
					file_sorter = require("telescope.sorters").get_fzy_sorter,
					file_ignore_patterns = {
						"node_modules",
						"dist",
						"build",
						"%.lock",
						"target",
					},
				},
			},
		})

		telescope.load_extension("fzf")
		telescope.load_extension("file_browser")
		telescope.load_extension("ui-select")
		telescope.load_extension("frecency")
	end,
}
