---@class catdaddy.util.shebang
local M = {}

--- Detects the shebang of the current file and sets the filetype to bash if it's a bash script
---@return nil
M.detect_shebang = function()
	local first_line = vim.fn.getline(1)
	if
		string.match(first_line, "^#!.*/bin/bash")
		or string.match(first_line, "^#!.*/bin/env%s+bash")
		or string.match(first_line, "^#!.*/bin/env%s+zsh")
		or string.match(first_line, "^#!.*/bin/sh")
	then
		-- check the file type first and if it's not already set to bash, set it to bash
		if vim.bo.filetype ~= "bash" then
			vim.bo.filetype = "bash"
		end
	end
end

return M
