---@class catdaddy.util.shebang
local M = {}

M.detect_shebang = function()
	local first_line = vim.fn.getline(1)
	if
		string.match(first_line, "^#!.*/bin/bash")
		or string.match(first_line, "^#!.*/bin/env%s+bash")
		or string.match(first_line, "^#!.*/bin/env%s+zsh")
		or string.match(first_line, "^#!.*/bin/sh")
	then
		vim.cmd("setfiletype bash")
	end
end

return M
