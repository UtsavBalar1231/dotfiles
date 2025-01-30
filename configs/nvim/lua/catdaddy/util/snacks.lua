---@class catdaddy.util.snacks
local M = {}

local uv = vim.uv or vim.loop

--- Global variable to store the current working directory
---@type string
M.cwd = ""

--- Global variable to store the current buffer file
--- This is used to track the current buffer file when opening the file browser
---@type string
M.current_buf_file = ""

---Get the current working directory of the buffer
---@return string
local function get_cwd_path()
	local buf_path = vim.api.nvim_buf_get_name(0)
	if not buf_path or buf_path:len() == 0 then
		return uv.cwd()
	end
	return vim.fn.isdirectory(buf_path) == 1 and buf_path or vim.fn.fnamemodify(buf_path, ":h")
end

--- Set the picker current working directory (cwd) and reload the picker
--- This function is used to set the new working directory and refresh the picker.
---@param picker any
---@param new_cwd string
function M.set_cwd(picker, new_cwd)
	local resolved_cwd = uv.fs_realpath(new_cwd) or new_cwd
	if resolved_cwd and vim.fn.isdirectory(resolved_cwd) == 1 then
		M.cwd = resolved_cwd
		picker:set_cwd(M.cwd)
		picker.title = " File Browser ( " .. M.cwd .. " )"
		picker.input:set()
		picker:find()
	end
end

--- Open the file browser picker with specified actions and keys
---@param opts? table  -- Optional configuration table
function M.file_browser(opts)
	opts = opts or {}
	M.cwd = opts.cwd or get_cwd_path()
	M.current_buf_file = vim.fs.basename(vim.api.nvim_buf_get_name(0))

	-- Configure the picker to use the actions and keys from options or defaults
	local picker = Snacks.picker.files({
		on_show = function(self)
			if M.current_buf_file ~= "" then
				local items_lookup = {}
				local function locate_current_file()
					if not items_lookup[M.current_buf_file] then
						for idx, item in ipairs(self.list.items) do
							items_lookup[item.file] = idx
						end
					end
					local target_idx = items_lookup[M.current_buf_file]
					if target_idx then
						self.list:view(target_idx)
					end
				end

				-- Wait for both finder and matcher completion
				local finder_done = false
				local matcher_done = false

				self.finder.task:on("done", function()
					finder_done = true
					if matcher_done then
						locate_current_file()
					end
				end)

				self.matcher.task:on("done", function()
					matcher_done = true
					if finder_done then
						locate_current_file()
					end
				end)
			end
		end,
		cwd = M.cwd,
		cmd = "fd",
		args = opts.args or {
			"--hidden",
			"--follow",
			"--max-depth=1",
			"--type=d",
			"--color=never",
			"-E",
			".git",
		},
		title = " File Browser ( " .. M.cwd .. " )",
		actions = opts.actions or {
			confirm = {
				action = function(self, selected)
					if not selected or selected.score == 0 then
						local new_path = vim.fs.joinpath(M.cwd, self:filter().pattern)
						self:close()
						vim.schedule(function()
							vim.cmd.edit(new_path)
						end)
						return
					end

					local file = vim.fs.joinpath(M.cwd, selected.file)
					if vim.fn.isdirectory(file) == 1 then
						M.set_cwd(self, file)
					else
						self:close()
						vim.schedule(function()
							vim.cmd.edit(file)
						end)
					end
				end,
			},
			navigate_parent = {
				action = function(self)
					local parent = vim.fs.dirname(M.cwd)
					if parent and parent ~= M.cwd then
						M.set_cwd(self, parent)
					end
				end,
			},
			change_directory = {
				action = function(self, selected)
					if selected then
						M.set_cwd(self, vim.fs.joinpath(M.cwd, selected.file))
						vim.cmd("tcd " .. vim.fn.fnameescape(M.cwd))
					end
				end,
			},
			copy = {
				action = function(_, selected)
					if selected then
						local file_name = vim.fn.fnamemodify(vim.fs.joinpath(M.cwd, selected.file), ":p")
						-- Copies to system clipboard
						vim.fn.setreg("+", file_name)
						Snacks.notify("Copied: " .. file_name, { level = "info" })
					end
				end,
			},
			delete = {
				action = function(self, selected)
					if selected then
						local file = vim.fs.joinpath(M.cwd, selected.file)
						vim.ui.input({ prompt = "Delete " .. selected.file .. "? [y/N] " }, function(confirm)
							if confirm == "y" then
								local success, err = os.remove(file)
								if success then
									Snacks.notify("Deleted: " .. file, { level = "info" })
									self:find() -- Refresh the picker
								else
									Snacks.notify("Delete failed: " .. err, { level = "error" })
								end
							end
						end)
					end
				end,
			},
			rename = {
				action = function(self, selected)
					if selected then
						local old_path = vim.fs.joinpath(M.cwd, selected.file)
						vim.ui.input(
							{ prompt = "Rename " .. selected.file .. " to: ", completion = "file" },
							function(new_name)
								if new_name and new_name ~= "" and new_name ~= selected.file then
									local new_path = vim.fs.joinpath(M.cwd, new_name)
									local success, err = os.rename(old_path, new_path)
									if success then
										Snacks.notify("Renamed to: " .. new_name, { level = "info" })
										self:find() -- Refresh the picker
									else
										Snacks.notify("Rename failed: " .. err, { level = "error" })
									end
								end
							end
						)
					end
				end,
			},

			new = {
				action = function(self)
					vim.ui.input({ prompt = "New file/folder: ", completion = "file" }, function(new_name)
						if new_name and new_name ~= "" then
							local new_path = vim.fs.joinpath(M.cwd, new_name)
							if new_name:sub(-1) == "/" then
								vim.fn.mkdir(new_path, "p")
								Snacks.notify("Created folder: " .. new_path, { level = "info" })
							else
								local file = io.open(new_path, "w")
								if file then
									file:close()
									Snacks.notify("Created file: " .. new_path, { level = "info" })
								else
									Snacks.notify("Failed to create file: " .. new_path, { level = "error" })
								end
							end
							self:find()
						end
					end)
				end,
			},
		},

		win = {
			input = {
				keys = opts.keys or {
					["<BS>"] = { "navigate_parent", mode = { "n" } },
					["<M-BS>"] = { "navigate_parent", mode = { "i" } },
					["<C-d>"] = { "change_directory", mode = { "i", "n" } },
					["<M-y>"] = { "copy", mode = { "i" } },
					["<M-r>"] = { "rename", mode = { "i" } },
					["<M-d>"] = { "delete", mode = { "i" } },
					["<M-n>"] = { "new", mode = { "i" } },
					["y"] = { "copy", mode = { "n" } },
					["r"] = { "rename", mode = { "n" } },
					["d"] = { "delete", mode = { "n" } },
					["N"] = { "new", mode = { "n" } },
				},
			},
		},

		layout = opts.layout or {
			preview = "main",
			preset = "vscode",
		},
	})

	-- If the initial directory is invalid, close the picker and show an error message
	uv.fs_stat(M.cwd, function(err, stat)
		if err or not stat then
			vim.schedule(function()
				picker:close()
				Snacks.notify(("Invalid initial directory: %s"):format(M.cwd), { level = "error" })
			end)
		end
	end)
end

return M
