---@class catdaddy.util
---@field config catdaddy.util.config
---@field colorscheme catdaddy.util.colorscheme
---@field root catdaddy.util.root
---@field health catdaddy.util.health
---@field lualine catdaddy.util.lualine
---@field shebang catdaddy.util.shebang
local M = {}

setmetatable(M, {
	__index = function(t, k)
		local status, module = pcall(require, "catdaddy.util." .. k)
		if not status then
			vim.notify("Module not found: " .. k, vim.log.levels.ERROR)
		end
		t[k] = module
		return module
	end,
})

function M.is_win()
	---@diagnostic disable-next-line: undefined-field
	return vim.uv.os_uname().sysname:find("Windows") ~= nil
end

--- Merge extended options with a default table of options
--- @param default? table The default table that you want to merge into
--- @param opts? table The new options that should be merged with the default table
--- @return table # The merged table
function M.extend_tbl(default, opts)
	opts = opts or {}
	return default and vim.tbl_deep_extend("force", default, opts) or opts
end

function M.is_loaded(name)
	local Config = require("lazy.core.config")
	return Config.plugins[name] and Config.plugins[name]._.loaded
end

---@param name string
---@param fn fun(name:string)
function M.on_load(name, fn)
	if M.is_loaded(name) then
		fn(name)
	else
		vim.api.nvim_create_autocmd("User", {
			pattern = "LazyLoad",
			callback = function(event)
				if event.data == name then
					fn(name)
					return true
				end
			end,
		})
	end
end

return M
