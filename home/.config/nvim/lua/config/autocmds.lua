-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

-- dd to delete quickfix items
autocmd("FileType", {
	pattern = "qf",
	callback = function(event)
		vim.keymap.set("n", "dd", function()
			local qf_items = vim.fn.getqflist()
			local lnum = vim.api.nvim_win_get_cursor(0)[1]
			table.remove(qf_items, lnum)
			vim.fn.setqflist(qf_items, "r")
			vim.api.nvim_win_set_cursor(0, { lnum, 0 })
		end, { buffer = event.buf, silent = true })
	end,
	desc = "Delete quickfix item with dd",
})

-- Edit files with :line syntax (e.g., file.txt:42)
autocmd("BufNew", {
	desc = "Edit files with :line at the end",
	pattern = "*",
	group = augroup("edit_line", { clear = true }),
	callback = function(args)
		local bufname = vim.api.nvim_buf_get_name(args.buf)
		local root, line = bufname:match("^(.*):(%d+)$")
		if vim.fn.filereadable(bufname) == 0 and root and line and vim.fn.filereadable(root) == 1 then
			vim.schedule(function()
				vim.cmd.edit({ args = { root } })
				pcall(vim.api.nvim_win_set_cursor, 0, { tonumber(line), 0 })
				vim.api.nvim_buf_delete(args.buf, { force = true })
			end)
		end
	end,
})

-- Auto hlsearch (Only highlight search when actively searching)
vim.on_key(function(char)
	if vim.fn.mode() == "n" then
		local hlsearch_active = vim.tbl_contains({ "<CR>", "n", "N", "*", "#", "?", "/" }, vim.fn.keytrans(char))
		vim.opt_local.hlsearch = hlsearch_active
	end
end, vim.api.nvim_create_namespace("auto_hlsearch"))

-- Shebang detection
autocmd("BufReadPost", {
	group = augroup("ShebangFiletype", { clear = true }),
	callback = function()
		require("util.shebang").detect_shebang()
	end,
	desc = "Detect shebang and set filetype",
})

-- Cursorline auto-toggle (Hide in insert mode)
autocmd({ "InsertLeave", "WinEnter" }, {
	group = augroup("auto_cursorline", { clear = true }),
	callback = function()
		if vim.w.auto_cursorline then
			vim.wo.cursorline = true
			vim.w.auto_cursorline = nil
		end
	end,
	desc = "Enable cursorline when entering window",
})

autocmd({ "InsertEnter", "WinLeave" }, {
	group = augroup("auto_cursorline", { clear = false }),
	callback = function()
		if vim.wo.cursorline then
			vim.w.auto_cursorline = true
			vim.wo.cursorline = false
		end
	end,
	desc = "Disable cursorline when leaving window",
})

-- Close the scratch preview automatically
autocmd({ "CursorMovedI", "InsertLeave" }, {
	desc = "Close the popup-menu automatically",
	pattern = "*",
	command = "if pumvisible() == 0 && !&pvw && getcmdwintype() == ''|pclose|endif",
	group = augroup("close_popup", { clear = true }),
})

-- Initialize URL utilities
require("util.url").setup()

-- Load Neovide configuration if running in Neovide
require("config.neovide")
