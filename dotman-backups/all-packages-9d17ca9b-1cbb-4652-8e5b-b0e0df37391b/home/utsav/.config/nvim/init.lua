-- Set bigfile flag as early as possible
vim.api.nvim_create_autocmd({ "BufReadPre", "BufNewFile" }, {
	pattern = "*",
	callback = function()
		local file = vim.fn.expand("%:p")
		if file == "" or vim.fn.isdirectory(file) ~= 0 then
			return
		end
		local size = vim.fn.getfsize(file)
		-- Set global flag (1MB threshold)
		vim.g.bigfile = size > 1000 * 1024
	end,
	desc = "Detect large files early",
})

vim.api.nvim_create_autocmd("VimEnter", {
	callback = function()
		vim.schedule(function()
			vim.api.nvim_exec_autocmds("BufReadPre", {})
		end)
	end,
	once = true,
})

require("catdaddy.config")
