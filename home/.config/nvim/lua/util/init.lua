---@class util
---@field shebang util.shebang
---@field url util.url
local M = {}

setmetatable(M, {
	__index = function(t, k)
		local status, module = pcall(require, "util." .. k)
		if not status then
			error("Failed to load module: " .. k)
		end
		t[k] = module
		return module
	end,
})

return M
