return {
	{
		"folke/snacks.nvim",
		priority = 1000,
		lazy = false,
		dependencies = { "nvim-lua/plenary.nvim" },
		---@type snacks.Config
		opts = {
			animate = { enabled = false },
			bigfile = { enabled = true },
			-- explorer = {
			-- 	enabled = true,
			-- 	preview = true,
			-- 	layout = { preset = "sidebar", preview = true },
			-- },
			image = { enabled = true },
			picker = {
				ui_select = true,
				sources = {
					explorer = {
						replace_netrw = true,
						layout = { preset = "sidebar", preview = true },
					},
				},
			},
			dashboard = {
				enabled = true,
				formats = {
					key = function(item)
						return { { "[", hl = "special" }, { item.key, hl = "key" }, { "]", hl = "special" } }
					end,
				},
				sections = {
					{
						section = "terminal",
						cmd = "fortune -s | cowsay",
						hl = "header",
						padding = 1,
						indent = 8,
					},
					{ section = "startup" },
					{ title = "MRU", padding = 1 },
					{ section = "recent_files", limit = 8, padding = 1 },
					{ title = "MRU ", file = vim.fn.fnamemodify(".", ":~"), padding = 1 },
					{ section = "recent_files", cwd = true, limit = 8, padding = 1 },
					{ title = "Bookmarks", padding = 1 },
					{ section = "keys" },
					{
						icon = " ",
						key = "p",
						desc = "Projects",
						action = ":lua Snacks.picker.projects()",
					},
				},
			},
			dim = { enabled = true },
			scope = { enabled = true },
			indent = {
				scope = { enabled = true },
				enabled = true,
				only_scope = true,
				filter = function(bufnr)
					return vim.bo.filetype ~= "bigfile"
						and vim.g.snacks_indent ~= false
						and vim.b[bufnr].snacks_indent ~= false
				end,
			},
			input = { enabled = true },
			notifier = {
				enabled = true,
				style = "compact",
			},
			quickfile = { enabled = true },
			scroll = { enabled = true },
			statuscolumn = { enabled = false },
			words = { enabled = true },
			debug = { enabled = false },
			styles = {
				notification = {
					border = Util.config.icons.border,
					wo = { wrap = true },
				},
			},
		},

		keys = {
			{
				"<leader>z",
				function()
					Snacks.zen()
				end,
				desc = "Toggle Zen Mode",
			},
			{
				"<leader>Z",
				function()
					Snacks.zen.zoom()
				end,
				desc = "Toggle Zoom",
			},
			{
				"<leader>.",
				function()
					Snacks.scratch()
				end,
				desc = "Toggle Scratch Buffer",
			},
			{
				"<leader>S",
				function()
					Snacks.scratch.select()
				end,
				desc = "Select Scratch Buffer",
			},
			{
				"<leader>n",
				function()
					Snacks.words.enable()
				end,
				desc = "LSP word references",
			},
			{
				"<leader>n[",
				function()
					Snacks.words.jump(1, true)
				end,
				desc = "LSP word references jump previous",
			},
			{
				"<leader>n]",
				function()
					Snacks.words.jump(-1, true)
				end,
				desc = "LSP word references jump ahead",
			},
			{
				"<leader>cl",
				function()
					Snacks.picker.lsp_config()
				end,
				desc = "Lsp Info",
			},
			{
				"<leader>dd",
				function()
					Snacks.bufdelete()
				end,
				desc = "Delete Buffer",
			},
			{
				"<leader>cR",
				function()
					Snacks.rename.rename_file()
				end,
				desc = "Rename File",
			},
			{
				"<leader>gB",
				function()
					Snacks.gitbrowse()
				end,
				desc = "Git Browse",
			},
			{
				"<leader>gb",
				function()
					Snacks.picker.git_log_line()
				end,
				desc = "Git Blame Line",
			},
			{
				"<leader>gf",
				function()
					Snacks.picker.git_log_file()
				end,
				desc = "Lazygit Current File History",
			},
			{
				"<leader>gg",
				function()
					Snacks.lazygit()
				end,
				desc = "Lazygit",
			},
			{
				"<leader>gl",
				function()
					Snacks.picker.git_log({ cwd = Util.root.git() })
				end,
				desc = "Lazygit Log (cwd)",
			},
			{
				"<leader>gL",
				function()
					Snacks.picker.git_log()
				end,
				{ desc = "Git Log (cwd)" },
			},
			{
				"<leader>un",
				function()
					Snacks.notifier.hide()
				end,
				desc = "Dismiss All Notifications",
			},
			{
				"<leader>T",
				function()
					Snacks.scratch({ icon = " ", name = "Todo", ft = "markdown", file = "~/dev/TODO.md" })
				end,
				desc = "Todo List",
			},
			{
				"<leader>ft",
				function()
					Snacks.terminal()
				end,
				desc = "Open Terminal",
			},
			{
				"<c-`>",
				function()
					Snacks.terminal.toggle()
				end,
				desc = "Toggle Terminal",
			},
			{
				"]]",
				function()
					Snacks.words.jump(vim.v.count1)
				end,
				desc = "Next Reference",
				mode = { "n", "t" },
			},
			{
				"[[",
				function()
					Snacks.words.jump(-vim.v.count1)
				end,
				desc = "Prev Reference",
				mode = { "n", "t" },
			},
			{
				"<leader>b,",
				function()
					Snacks.picker.buffers()
				end,
				desc = "Buffers",
			},
			{
				"<leader>/",
				function()
					Snacks.picker.grep()
				end,
				desc = "Grep",
			},
			{
				"<leader>:",
				function()
					Snacks.picker.command_history()
				end,
				desc = "Command History",
			},
			-- find
			{
				"<leader>fb",
				function()
					Snacks.picker.buffers()
				end,
				desc = "Buffers",
			},
			{
				"<leader>fB",
				function()
					Snacks.picker.buffers({ hidden = true, nofile = true })
				end,
				desc = "Buffers (all)",
			},
			{
				"<leader>fc",
				function()
					Snacks.picker.files({ cwd = vim.fn.stdpath("config") })
				end,
				desc = "Find Config File",
			},
			{
				"<leader>fF",
				function()
					Util.snacks.file_browser({})
				end,
				desc = "Find Files",
			},
			{
				"<leader>fF",
				function()
					Snacks.picker.files()
				end,
				desc = "Find Files in Current Buffer Directory",
			},
			{
				"<leader>ff",
				function()
					Snacks.picker.files({ cwd = vim.fn.expand("%:p:h") })
				end,
				desc = "Find Files",
			},
			{
				"<leader>fe",
				function()
					Snacks.explorer({ cwd = Util.root() })
				end,
				desc = "Find Files in Current Buffer Directory",
			},
			{
				"<leader>fE",
				function()
					Snacks.explorer({})
				end,
				desc = "Find Files in Current Buffer Directory",
			},
			{
				"<leader>gf",
				function()
					Snacks.picker.git_files()
				end,
				desc = "Find Git Files",
			},
			{
				"<leader>fr",
				function()
					Snacks.picker.recent()
				end,
				desc = "Recent",
			},
			{
				"<leader>fR",
				function()
					Snacks.picker.recent({ filter = { cwd = true } })
				end,
				desc = "Recent (cwd)",
			},
			{
				"<leader>gs",
				function()
					Snacks.picker.git_status()
				end,
				desc = "Git Status",
			},
			{
				"<leader>gS",
				function()
					Snacks.picker.git_stash()
				end,
				desc = "Git Stash",
			},
			{
				"<leader>sb",
				function()
					Snacks.picker.lines()
				end,
				desc = "Buffer Lines",
			},
			{
				"<leader>sB",
				function()
					Snacks.picker.grep_buffers()
				end,
				desc = "Grep Open Buffers",
			},
			{
				"<leader>fg",
				function()
					Snacks.picker.grep()
				end,
				desc = "Grep",
			},
			{
				"<leader>fG",
				function()
					Snacks.picker.grep({ cwd = vim.fn.fnamemodify(vim.fn.expand("%:p"), ":h") })
				end,
				desc = "Grep in Parent Directory",
			},
			{
				"<leader>sw",
				function()
					Snacks.picker.grep_word()
				end,
				desc = "Visual selection or word",
				mode = { "n", "x" },
			},
			-- search
			{
				'<leader>s"',
				function()
					Snacks.picker.registers()
				end,
				desc = "Registers",
			},
			{
				"<leader>s/",
				function()
					Snacks.picker.search_history()
				end,
				desc = "Search History",
			},
			{
				"<leader>sa",
				function()
					Snacks.picker.autocmds()
				end,
				desc = "Autocmds",
			},
			{
				"<leader>sc",
				function()
					Snacks.picker.command_history()
				end,
				desc = "Command History",
			},
			{
				"<leader>sC",
				function()
					Snacks.picker.commands()
				end,
				desc = "Commands",
			},
			{
				"<leader>sd",
				function()
					Snacks.picker.diagnostics()
				end,
				desc = "Diagnostics",
			},
			{
				"<leader>sD",
				function()
					Snacks.picker.diagnostics_buffer()
				end,
				desc = "Buffer Diagnostics",
			},
			{
				"<leader>sh",
				function()
					Snacks.picker.help()
				end,
				desc = "Help Pages",
			},
			{
				"<leader>sH",
				function()
					Snacks.picker.highlights()
				end,
				desc = "Highlights",
			},
			{
				"<leader>sj",
				function()
					Snacks.picker.jumps()
				end,
				desc = "Jumps",
			},
			{
				"<leader>fk",
				function()
					Snacks.picker.keymaps()
				end,
				desc = "Keymaps",
			},
			{
				"<leader>fl",
				function()
					Snacks.picker.loclist()
				end,
				desc = "Location List",
			},
			{
				"<leader>fm",
				function()
					Snacks.picker.man()
				end,
				desc = "Man Pages",
			},
			{
				"<leader>sm",
				function()
					Snacks.picker.marks()
				end,
				desc = "Marks",
			},
			{
				"<leader>sR",
				function()
					Snacks.picker.resume()
				end,
				desc = "Resume",
			},
			{
				"<leader>fq",
				function()
					Snacks.picker.qflist()
				end,
				desc = "Quickfix List",
			},
			{
				"<leader>uC",
				function()
					local opts = {
						items = Util.colorscheme.get_available_colorschemes(),
						format = "text",
						title = " Colorschemes ",
						preview = "colorscheme",
						confirm = function(picker, item)
							picker:close()
							if item then
								picker.preview.state.colorscheme = nil
								vim.schedule(function()
									vim.cmd("colorscheme " .. item.text)
									Util.colorscheme.set_colorscheme(item.text)
								end)
							end
						end,
					}
					Snacks.picker.pick(opts)
				end,
				desc = "Colorschemes",
			},
			{
				"<leader>fp",
				function()
					Snacks.picker.projects()
				end,
				desc = "Projects",
			},
			-- LSP
			{
				"gd",
				function()
					Snacks.picker.lsp_definitions()
				end,
				desc = "LSP: Goto Definition",
			},
			{
				"gr",
				function()
					Snacks.picker.lsp_references()
				end,
				nowait = true,
				desc = "LSP: References",
			},
			{
				"gi",
				function()
					Snacks.picker.lsp_implementations()
				end,
				desc = "LSP: Goto Implementation",
			},
			{
				"gy",
				function()
					Snacks.picker.lsp_type_definitions()
				end,
				desc = "LSP: Goto Type Definition",
			},
			{
				"<leader>fs",
				function()
					Snacks.picker.lsp_symbols()
				end,
				desc = "LSP: Symbols",
			},
			{
				"<leader>fS",
				function()
					Snacks.picker.lsp_workspace_symbols()
				end,
				desc = "LSP: Workspace symbols",
			},
		},
		init = function()
			vim.g.snacks_animate = false
			vim.api.nvim_create_autocmd("User", {
				pattern = "VeryLazy",
				callback = function()
					-- Setup some globals for debugging (lazy-loaded)
					_G.dd = function(...)
						Snacks.debug.inspect(...)
					end
					_G.bt = function()
						Snacks.debug.backtrace()
					end
					vim.print = _G.dd -- Override print to use snacks for `:=` command

					-- Create some toggle mappings
					Snacks.toggle.option("spell", { name = "Spelling" }):map("<leader>us")
					Snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>uw")
					Snacks.toggle.option("relativenumber", { name = "Relative Number" }):map("<leader>uL")
					Snacks.toggle.diagnostics():map("<leader>ud")
					Snacks.toggle.line_number():map("<leader>ul")
					Snacks.toggle
						.option("conceallevel", { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2 })
						:map("<leader>uc")
					Snacks.toggle.treesitter():map("<leader>uT")
					Snacks.toggle
						.option("background", { off = "light", on = "dark", name = "Dark Background" })
						:map("<leader>ub")
					Snacks.toggle.inlay_hints():map("<leader>uh")
					Snacks.toggle.indent():map("<leader>ug")
					Snacks.toggle.dim():map("<leader>uD")
				end,
			})

			if vim.o.shell:find("zsh") or vim.o.shell:find("fish") then
				vim.api.nvim_create_autocmd("TermEnter", {
					group = vim.api.nvim_create_augroup("shell_vi_mode", {}),
					pattern = "term://*" .. vim.o.shell,
					callback = function(event)
						if vim.bo[event.buf].filetype ~= "snacks_terminal" then
							return
						end
						vim.schedule(function()
							if vim.api.nvim_get_current_line():match("^❮ .*") then
								vim.api.nvim_feedkeys(vim.keycode("a"), "n", false)
							end
						end)
					end,
					desc = "Enter insert mode when starting a new line in snacks_terminal",
				})
			end

			---@type table<number, {token:lsp.ProgressToken, msg:string, done:boolean}[]>
			local progress = vim.defaulttable()
			vim.api.nvim_create_autocmd("LspProgress", {
				---@param ev {data: {client_id: integer, params: lsp.ProgressParams}}
				callback = function(ev)
					local client = vim.lsp.get_client_by_id(ev.data.client_id)
					local value = ev.data.params.value --[[@as {percentage?: number, title?: string, message?: string, kind: "begin" | "report" | "end"}]]
					if not client or type(value) ~= "table" then
						return
					end
					local p = progress[client.id]

					for i = 1, #p + 1 do
						if i == #p + 1 or p[i].token == ev.data.params.token then
							p[i] = {
								token = ev.data.params.token,
								msg = ("[%3d%%] %s%s"):format(
									value.kind == "end" and 100 or value.percentage or 100,
									value.title or "",
									value.message and (" **%s**"):format(value.message) or ""
								),
								done = value.kind == "end",
							}
							break
						end
					end

					local msg = {} ---@type string[]
					progress[client.id] = vim.tbl_filter(function(v)
						return table.insert(msg, v.msg) or not v.done
					end, p)

					local spinner = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
					vim.notify(table.concat(msg, "\n"), vim.log.levels.INFO, {
						id = "lsp_progress",
						title = client.name,
						opts = function(notif)
							notif.icon = #progress[client.id] == 0 and " "
								---@diagnostic disable-next-line: undefined-field
								or spinner[math.floor(vim.uv.hrtime() / (1e6 * 80)) % #spinner + 1]
						end,
					})
				end,
			})

			vim.api.nvim_create_autocmd("BufEnter", {
				group = vim.api.nvim_create_augroup("snacks_explorer_start_directory", { clear = true }),
				desc = "Start Snacks Explorer with directory",
				once = true,
				callback = function()
					local dir = vim.fn.argv(0) --[[@as string]]
					if dir ~= "" and vim.fn.isdirectory(dir) == 1 then
						Snacks.picker.explorer({ cwd = dir })
					end
				end,
			})
		end,
	},
	{
		"folke/trouble.nvim",
		optional = true,
		specs = {
			"folke/snacks.nvim",
			opts = function(_, opts)
				return vim.tbl_deep_extend("force", opts or {}, {
					picker = {
						actions = {
							trouble_open = function(...)
								return require("trouble.sources.snacks").actions.trouble_open.action(...)
							end,
						},
						win = {
							input = {
								keys = {
									["<a-t>"] = {
										"trouble_open",
										mode = { "n", "i" },
									},
								},
							},
						},
					},
				})
			end,
		},
	},

	{
		"folke/flash.nvim",
		optional = true,
		specs = {
			{
				"folke/snacks.nvim",
				opts = {
					picker = {
						win = {
							input = {
								keys = {
									["<a-s>"] = { "flash", mode = { "n", "i" } },
									["s"] = { "flash" },
								},
							},
						},
						actions = {
							flash = function(picker)
								require("flash").jump({
									pattern = "^",
									label = { after = { 0, 0 } },
									search = {
										mode = "search",
										exclude = {
											function(win)
												return vim.bo[vim.api.nvim_win_get_buf(win)].filetype
													~= "snacks_picker_list"
											end,
										},
									},
									action = function(match)
										local idx = picker.list:row2idx(match.pos[1])
										picker.list:move(idx, true)
									end,
								})
							end,
						},
					},
				},
			},
		},
	},
}
