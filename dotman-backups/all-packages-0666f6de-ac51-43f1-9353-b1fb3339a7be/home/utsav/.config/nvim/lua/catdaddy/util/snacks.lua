---@class catdaddy.util.snacks
local M = {}

local uv = vim.uv or vim.loop

---@class catdaddy.util.snacks.State
---@field cwd string
---@field picker snacks.Picker.ref
local State = {}
State.__index = State

---Get the current working directory of the buffer
---@return string
local function get_cwd_path()
    if package.loaded["oil"] then
        local oil = require("oil")
        if oil.get_current_dir then
            local oil_dir = oil.get_current_dir()
            if oil_dir then
                return vim.fn.fnamemodify(oil_dir, ":h")
            end
        end
    end

    local buf_path = vim.api.nvim_buf_get_name(0)
    if buf_path == "" then
        return uv.cwd()
    end
    return vim.fn.isdirectory(buf_path) == 1 and buf_path or vim.fn.fnamemodify(buf_path, ":h")
end

---Create a new state object
---@param picker snacks.Picker
---@return catdaddy.util.snacks.State
function State.new(picker)
	local self = setmetatable({}, State)
	self.picker = picker:ref()
	self.cwd = get_cwd_path()
	return self
end

---@param picker snacks.Picker
---@return catdaddy.util.snacks.State
function M.get_state(picker)
	if not M._state then
		M._state = setmetatable({}, { __mode = "k" })
	end
	if not M._state[picker] then
		M._state[picker] = State.new(picker)
	end
	return M._state[picker]
end

---@param picker snacks.Picker
---@param new_cwd string
---@return nil
function M.set_cwd(picker, new_cwd)
	local state = M.get_state(picker)
	local resolved_cwd = uv.fs_realpath(new_cwd) or new_cwd
	if resolved_cwd and vim.fn.isdirectory(resolved_cwd) == 1 then
		state.cwd = resolved_cwd
		picker:set_cwd(state.cwd)
		picker.opts.title = " File Browser ( " .. state.cwd .. " )"
		picker:find()
	end
end

---@param picker snacks.Picker
---@param target string
local function locate_item(picker, target)
	vim.schedule(function()
		for idx, item in ipairs(picker.list.items) do
			if item.file == target then
				picker.list:view(idx)
				break
			end
		end
	end)
end

---@param opts table
function M.file_browser(opts)
	opts = opts or {}
	local current_buf = vim.api.nvim_get_current_buf()
	local current_file = vim.api.nvim_buf_get_name(current_buf)

	-- Create picker first
	local picker = Snacks.picker.files(vim.tbl_deep_extend("force", {
		cwd = get_cwd_path(),
		cmd = "fd",
		args = {
			"--hidden",
			"--follow",
			"--max-depth=1",
			"--color=never",
			"--exclude",
			".git",
		},
		title = " File Browser ( " .. get_cwd_path() .. " )",
		actions = {
			confirm = function(self, selected)
				if not selected then
					return
				end
				local state = M.get_state(self)
				local full_path = vim.fs.joinpath(state.cwd, selected.file)

				if vim.fn.isdirectory(full_path) == 1 then
					M.set_cwd(self, full_path)
				else
					self:close()
					vim.schedule(function()
						vim.cmd.edit(full_path)
					end)
				end
			end,

			navigate_parent = function(self)
				local state = M.get_state(self)
				local parent = vim.fs.dirname(state.cwd)
				if parent ~= state.cwd then
					M.set_cwd(self, parent)
				end
			end,

			create = function(self)
				local state = M.get_state(self)
				vim.ui.input({ prompt = "Create: " }, function(input)
					if not input or input == "" then
						return
					end

					local is_dir = input:sub(-1) == "/"
					local target = is_dir and input:sub(1, -2) or input
					local full_path = vim.fs.joinpath(state.cwd, target)

					if is_dir then
						vim.fn.mkdir(full_path, "p")
					else
						local parent = vim.fs.dirname(full_path)
						vim.fn.mkdir(parent, "p")
						io.open(full_path, "w"):close()
					end

					self:find()
					locate_item(self, target)
				end)
			end,

			rename = function(self, selected)
				if not selected then
					return
				end
				local state = M.get_state(self)
				vim.ui.input({ prompt = "Rename to: ", default = selected.file }, function(new_name)
					if not new_name or new_name == "" then
						return
					end

					local old_path = vim.fs.joinpath(state.cwd, selected.file)
					local new_path = vim.fs.joinpath(state.cwd, new_name)

					os.rename(old_path, new_path)
					self:find()
				end)
			end,

			delete = function(self, selected)
				if not selected then
					return
				end
				local state = M.get_state(self)
				vim.ui.input({ prompt = "Delete? (y/n): " }, function(confirm)
					if confirm:lower() ~= "y" then
						return
					end

					local path = vim.fs.joinpath(state.cwd, selected.file)
					vim.fn.delete(path, "rf")
					self:find()
				end)
			end,
		},
		win = {
			input = {
				keys = {
					["<BS>"] = "navigate_parent",
					["<C-p>"] = "create",
					["<C-r>"] = "rename",
					["<C-d>"] = "delete",
				},
			},
		},
		layout = {
			preset = "sidebar",
			preview = false,
		},
	}, opts))

	-- Initialize state after picker creation
	local state = M.get_state(picker)

	-- Initial file location
	if current_file ~= "" then
		locate_item(picker, vim.fs.basename(current_file))
	end

	-- Validate directory using state's cwd
	uv.fs_stat(state.cwd, function(err, stat)
		if err or not stat then
			vim.schedule(function()
				state:close()
				Snacks.notify("Invalid directory: " .. state.cwd, "error")
			end)
		end
	end)
end

return M
