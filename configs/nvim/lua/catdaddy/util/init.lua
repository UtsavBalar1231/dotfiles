---@class util
---@field colorscheme util.colorscheme
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

--- Merge extended options with a default table of options
--- @param default? table The default table that you want to merge into
--- @param opts? table The new options that should be merged with the default table
--- @return table # The merged table
function M.extend_tbl(default, opts)
	opts = opts or {}
	return default and vim.tbl_deep_extend("force", default, opts) or opts
end

return M
