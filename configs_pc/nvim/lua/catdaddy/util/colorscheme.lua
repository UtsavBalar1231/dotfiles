---@class util.colorscheme
local M = {}

local cs_config_file = vim.fn.stdpath("config") .. "/lua/catdaddy/util/colorscheme.json"

--- Write a default colorscheme to the config file
local function write_default_colorscheme()
	local file = io.open(cs_config_file, "w")
	if file then
		local colorscheme = "default"
		file:write(vim.fn.json_encode({ colorscheme = colorscheme }))
		file:close()
	else
		vim.notify("Failed to write default colorscheme", vim.log.levels.ERROR)
	end
end

--- Save the current colorscheme to a config file
---@param colorscheme string The colorscheme to save
function M.set_colorscheme(colorscheme)
	local file = io.open(cs_config_file, "w")
	if file then
		file:write(vim.fn.json_encode({ colorscheme = colorscheme }))
		file:close()
		vim.notify("Colorscheme saved: " .. colorscheme)
	else
		vim.notify("Failed to save colorscheme", vim.log.levels.ERROR)
	end
end

--- Load the saved colorscheme from the config file or set to a default
function M.load_colorscheme()
	local file = io.open(cs_config_file, "r")
	if file then
		local data = file:read("*a")
		file:close()
		local ok, decoded = pcall(vim.fn.json_decode, data)
		if ok and decoded.colorscheme then
			vim.cmd("colorscheme " .. decoded.colorscheme)
			return
		end
	else
		vim.notify("No saved colorscheme found. Using default", vim.log.levels.WARN)
	end
	-- If the file doesn't exist or is invalid, write the default colorscheme
	write_default_colorscheme()
	vim.cmd("colorscheme " .. "default")
end

--- Get the saved colorscheme from the config file or return the default
---@return string The colorscheme name
function M.get_colorscheme()
	local file = io.open(cs_config_file, "r")
	if file then
		local data = file:read("*a")
		file:close()
		local ok, decoded = pcall(vim.fn.json_decode, data)
		if ok and decoded.colorscheme then
			return decoded.colorscheme
		else
			vim.notify("Failed to decode colorscheme file. Returning default", vim.log.levels.WARN)
			write_default_colorscheme()
			return "default"
		end
	else
		vim.notify("No saved colorscheme found. Returning default", vim.log.levels.WARN)
		write_default_colorscheme()
		return "default"
	end
end

-- Utility function to disable specified colorschemes
---@param colorschemes string[] List of colorschemes to disable
function M.disable_colorschemes(colorschemes)
	vim.opt.wildignore:append(colorschemes)
end

return M
