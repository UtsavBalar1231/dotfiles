---@class util.shebang
local M = {}

M.detect_shebang = function()
	local filename = vim.fn.expand("%:t")
	local first_line = vim.fn.getline(1)

	-- Pattern matching for common shell files and shebangs
	if filename:match("%.zsh$") or filename:match("^%.zshrc") then
		vim.bo.filetype = "zsh"
	elseif filename:match("%.sh$") or filename:match("%.bash$") or filename:match("^%.bashrc") then
		vim.bo.filetype = "bash"
	else
		-- Shebang detection for various shell types
		if first_line:match("^#!.*/bin/env?%s+[bz]?sh") or first_line:match("^#!.*/bin/(bash|sh|zsh)") then
			vim.bo.filetype = "bash"
		end
	end
end

return M
