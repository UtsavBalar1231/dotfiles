---@class catdaddy.util.colorscheme
local M = {}

local colorscheme_config_file = vim.fn.stdpath("config") .. "/lua/catdaddy/util/colorscheme.json"
local default_colorscheme = "default"

--- Write a colorscheme to the config file
---@param colorscheme string The colorscheme to write
local function write_colorscheme(colorscheme)
	local file, err = io.open(colorscheme_config_file, "w")
	if not file then
		vim.notify("Failed to write colorscheme: " .. (err or "unknown error"), vim.log.levels.ERROR)
		return false
	end
	file:write(vim.fn.json_encode({ colorscheme = colorscheme }))
	file:close()
	return true
end

--- Read the saved colorscheme from the config file
---@return string|nil The saved colorscheme, or nil if not found
local function read_colorscheme()
	local file, err = io.open(colorscheme_config_file, "r")
	if not file then
		vim.notify("Failed to read colorscheme: " .. (err or "not found"), vim.log.levels.ERROR)
		return nil
	end
	local data = file:read("*a")
	file:close()
	local ok, decoded = pcall(vim.fn.json_decode, data)
	if ok and decoded.colorscheme then
		return decoded.colorscheme
	end
	vim.notify("Invalid colorscheme data in config file", vim.log.levels.ERROR)
	return nil
end

--- Save the current colorscheme to a config file
---@param colorscheme string The colorscheme to save
function M.set_colorscheme(colorscheme)
	if write_colorscheme(colorscheme) then
		vim.notify("Colorscheme saved: " .. colorscheme)
	end
end

--- Load the saved colorscheme from the config file or set to default
function M.load_colorscheme()
	local colorscheme = read_colorscheme() or default_colorscheme
	vim.cmd("colorscheme " .. colorscheme)
	if colorscheme == default_colorscheme then
		write_colorscheme(default_colorscheme)
	end
end

--- Get the saved colorscheme or return the default
---@return string The colorscheme name
function M.get_colorscheme()
	return read_colorscheme() or default_colorscheme
end

--- Get a list of built-in colorschemes
---@return string[] A list of built-in colorscheme names
function M.get_builtin_colorschemes()
	return {
		"blue",
		"darkblue",
		"default",
		"delek",
		"desert",
		"elflord",
		"evening",
		"habamax",
		"industry",
		"koehler",
		"lunaperche",
		"morning",
		"murphy",
		"pablo",
		"peachpuff",
		"quiet",
		"retrobox",
		"ron",
		"shine",
		"slate",
		"sorbet",
		"torte",
		"vim",
		"wildcharm",
		"zaibatsu",
		"zellner",
	}
end

--- Get a list of available colorschemes
---@return table A list of colorscheme names
function M.get_available_colorschemes()
	local rtp = vim.o.runtimepath
	if package.loaded.lazy then
		rtp = rtp .. "," .. table.concat(require("lazy.core.util").get_unloaded_rtp(""), ",")
	end
	local files = vim.fn.globpath(rtp, "colors/*.{vim,lua}", true, true)
	local builtins = M.get_builtin_colorschemes()
	return vim.tbl_map(
		function(file)
			return {
				text = vim.fn.fnamemodify(file, ":t:r"),
				file = file,
			}
		end,
		vim.tbl_filter(function(file)
			local name = vim.fn.fnamemodify(file, ":t:r")
			return not vim.tbl_contains(builtins, name)
		end, files)
	)
end

return M
