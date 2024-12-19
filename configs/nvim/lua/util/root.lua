local M = {}

-- Function to find the root directory
function M.get(opts)
	opts = opts or {}
	local normalize = opts.normalize or false
	local patterns = opts.patterns or { ".git", "Makefile", "package.json" }
	local cwd = vim.fn.getcwd()

	-- Search for a root marker
	for _, pattern in ipairs(patterns) do
		local root = vim.fn.finddir(pattern, cwd .. ";")
		if root and root ~= "" then
			return normalize and vim.fn.fnamemodify(root, ":p:h") or root
		end
	end

	-- Default to current working directory
	return cwd
end

return M
