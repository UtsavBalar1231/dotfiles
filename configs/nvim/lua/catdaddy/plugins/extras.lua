return {
	{
		"lambdalisue/suda.vim",
		cmd = { "SudaRead", "SudaWrite" },
		enabled = not vim.g.vscode,
		opts = function()
			vim.keymap.set(
				"c",
				"w!!",
				":SudaWrite",
				{ noremap = true, script = true, desc = "Write with sudo privillege" }
			)
		end,
	},
	{
		"leath-dub/snipe.nvim",
		keys = {
			{
				"Bb",
				function()
					require("snipe").open_buffer_menu()
				end,
				desc = "Open Snipe buffer menu",
			},
			{
				"Ss",
				function()
					require("snipe").open_buffer_menu()
				end,
				desc = "Open Snipe buffer menu",
			},
		},
		opts = function()
			local uv = vim.uv or vim.loop
			local menu
			local items

			local prev = uv.cwd()
			local curr = prev

			local function new_dir(dir_name)
				prev = curr

				local cwd = uv.cwd()

				if uv.fs_realpath(dir_name) == cwd then
					dir_name = cwd
				end

				local dir = uv.fs_opendir(dir_name)
				if dir == nil then
					return
				end

				items = {}
				while true do
					local ent = dir:readdir()
					if not ent then
						break
					end

					if dir_name ~= uv.cwd() then
						ent[1].name = dir_name .. "/" .. ent[1].name
					end

					table.insert(items, ent[1])
				end
				dir:closedir()

				curr = dir_name
			end

			local function set_keymaps(m)
				local nav_next = function()
					m:goto_next_page()
					m:reopen()
				end

				local nav_prev = function()
					m:goto_prev_page()
					m:reopen()
				end

				vim.keymap.set("n", "J", nav_next, { nowait = true, buffer = m.buf })
				vim.keymap.set("n", "K", nav_prev, { nowait = true, buffer = m.buf })
				vim.keymap.set("n", "<esc>", function()
					m:close()
				end, { nowait = true, buffer = m.buf })
				vim.keymap.set("n", "-", function()
					new_dir(prev)
					m.items = items
					m:reopen()
				end)
				vim.keymap.set("n", "..", function()
					local cwd = uv.fs_realpath(uv.cwd())
					local cur = uv.fs_realpath(vim.fs.dirname(m.items[1].name))
					local dir = uv.fs_realpath(vim.fs.dirname(cur))

					if uv.fs_realpath(dir) == cwd then
						new_dir(cwd)
						m.items = items
						m:reopen()
						return
					end

					local tot = 0
					local matched = 0
					local fail = false
					local unmatched = ""

					local cwd_it = cwd:gmatch("[^/]+")
					local dir_it = dir:gmatch("[^/]+")
					local dual_it = function()
						return cwd_it(), dir_it()
					end

					for cwd_d, dir_d in dual_it do
						if cwd_d == dir_d and not fail then
							matched = matched + 1
						else
							if not fail then
								unmatched = unmatched .. (dir_d or "")
							else
								unmatched = unmatched .. "/" .. (dir_d or "")
							end
							fail = true
						end
						tot = tot + 1
					end

					if tot == matched then
						unmatched = dir:gsub(cwd, "")
					end

					unmatched = unmatched:gsub("^/", "")
					unmatched = unmatched:gsub("/$", "")
					unmatched = unmatched == "/" and "" or unmatched

					-- how many ".." is determined by tot - matched
					local backs = tot - matched
					local pfx = ("../"):rep(backs):gsub("/$", "")

					new_dir(pfx .. unmatched)
					m.items = items
					m:reopen()
				end, { nowait = true, buffer = m.buf })
			end

			local function open_file_manager()
				if menu == nil then
					menu = require("snipe.menu"):new({ position = "bottomleft" })
					menu:add_new_buffer_callback(set_keymaps)
				end

				new_dir(uv.cwd())
				menu:open(items, function(m, i)
					if m.items[i].type == "directory" then
						new_dir(m.items[i].name)
						m.items = items
						m:reopen()
					else
						m:close()
						vim.cmd.edit(m.items[i].name)
					end
				end, function(item)
					if item.type == "directory" then
						return item.name .. "/"
					end
					return item.name
				end)
			end

			vim.keymap.set("n", "cd", open_file_manager)
		end,
	},
	-- search/replace in multiple files
	{
		"MagicDuck/grug-far.nvim",
		opts = { headerMaxWidth = 80 },
		cmd = "GrugFar",
		enabled = not vim.g.vscode,
		keys = {
			{
				"<leader>sr",
				function()
					local grug = require("grug-far")
					local ext = vim.bo.buftype == "" and vim.fn.expand("%:e")
					grug.open({
						transient = true,
						prefills = {
							filesFilter = ext and ext ~= "" and "*." .. ext or nil,
						},
					})
				end,
				mode = { "n", "v" },
				desc = "Search and Replace",
			},
		},
	},
	{
		"aileot/ex-colors.nvim",
		lazy = true,
		cmd = "ExColors",
		---@type ExColors.Config
		opts = {},
	},
}
