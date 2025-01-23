local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

vim.on_key(function(char)
	if vim.fn.mode() == "n" then
		local hlsearch_active = vim.tbl_contains({ "<CR>", "n", "N", "*", "#", "?", "/" }, vim.fn.keytrans(char))
		vim.opt_local.hlsearch = hlsearch_active
	end
end, vim.api.nvim_create_namespace("auto_hlsearch"))

autocmd("FileType", {
	group = augroup("q_close_windows", { clear = true }),
	pattern = {
		"DressingSelect",
		"Jaq",
		"PlenaryTestPopup",
		"checkhealth",
		"dap-float",
		"dbout",
		"floaterm",
		"gitsigns.blame",
		"grug-far",
		"help",
		"lir",
		"lsp-installer",
		"lspinfo",
		"man",
		"neotest-output",
		"neotest-output-panel",
		"neotest-summary",
		"notify",
		"null-ls-info",
		"qf",
		"spectre_panel",
		"startuptime",
		"tsplayground",
	},
	callback = function(event)
		vim.bo[event.buf].buflisted = false
		vim.schedule(function()
			vim.keymap.set("n", "q", function()
				vim.cmd("close")
				pcall(vim.api.nvim_buf_delete, event.buf, { force = true })
			end, { buffer = event.buf, silent = true })
		end)
	end,
	desc = "Close windows for certain filetypes",
})

autocmd("FileType", {
	group = augroup("man_unlisted", { clear = true }),
	pattern = "man",
	callback = function(event)
		vim.bo[event.buf].buflisted = false
	end,
	desc = "Unlist man pages",
})

autocmd("TextYankPost", {
	group = augroup("YankHighlight", { clear = true }),
	pattern = "*",
	callback = function()
		(vim.hl or vim.highlight).on_yank()
	end,
	desc = "Highlight yanked text",
})

autocmd("BufReadPost", {
	group = augroup("last_loc", { clear = true }),
	pattern = "*",
	callback = function(event)
		local exclude = { "gitcommit" }
		local buf = event.buf
		if vim.tbl_contains(exclude, vim.bo[buf].filetype) or vim.b[buf].lazyvim_last_loc then
			return
		end
		vim.b[buf].lazyvim_last_loc = true
		local mark = vim.api.nvim_buf_get_mark(buf, '"')
		local lcount = vim.api.nvim_buf_line_count(buf)
		if mark[1] > 0 and mark[1] <= lcount then
			pcall(vim.api.nvim_win_set_cursor, 0, mark)
		end
	end,
	desc = "Restore last cursor position",
})

autocmd("VimResized", {
	group = augroup("resize_splits", { clear = true }),
	pattern = "*",
	callback = function()
		local current_tab = vim.fn.tabpagenr()
		vim.cmd("tabdo wincmd =")
		vim.cmd("tabnext " .. current_tab)
	end,
	desc = "Resize splits on VimResized",
})

autocmd("FileType", {
	group = augroup("wrap_spell", { clear = true }),
	pattern = { "text", "plaintex", "typst", "gitcommit", "markdown" },
	callback = function()
		vim.opt_local.wrap = true
		vim.opt_local.spell = true
	end,
	desc = "Enable wrap and spell for text files",
})

autocmd("BufWritePre", {
	group = augroup("auto_create_dir", { clear = true }),
	callback = function(event)
		if not event.match:match("^%w%w+:[\\/][\\/]") then
			---@diagnostic disable-next-line: undefined-field
			local file = vim.uv.fs_realpath(event.match) or event.match
			vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
		end
	end,
	desc = "Auto create directory if it doesn't exist",
})

autocmd("TermOpen", {
	group = augroup("terminal", { clear = true }),
	callback = function()
		vim.opt_local.number = false
		vim.opt_local.relativenumber = false
		vim.opt_local.signcolumn = "no"
		vim.opt_local.spell = false
		vim.opt_local.wrap = true
		vim.opt_local.foldcolumn = "0"
	end,
	desc = "Set options for terminal buffers",
})

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
	desc = "Delete quickfix item",
})

autocmd("BufReadPost", {
	group = augroup("ShebangFiletype", { clear = true }),
	callback = function()
		require("catdaddy.util.shebang").detect_shebang()
	end,
	desc = "Detect shebang and set filetype",
})

autocmd({ "InsertLeave", "WinEnter" }, {
	callback = function()
		if vim.w.auto_cursorline then
			vim.wo.cursorline = true
			vim.w.auto_cursorline = nil
		end
	end,
	desc = "Enable cursorline when entering window",
})

autocmd({ "InsertEnter", "WinLeave" }, {
	callback = function()
		if vim.wo.cursorline then
			vim.w.auto_cursorline = true
			vim.wo.cursorline = false
		end
	end,
	desc = "Disable cursorline when leaving window",
})

autocmd("FocusGained", {
	desc = "Reload files from disk when we focus vim",
	pattern = "*",
	command = "if getcmdwintype() == '' | checktime | endif",
	group = augroup("reload_files", { clear = true }),
})

autocmd("BufEnter", {
	desc = "Every time we enter an unmodified buffer, check if it changed on disk",
	pattern = "*",
	command = "if &buftype == '' && !&modified && expand('%') != '' | exec 'checktime ' . expand('<abuf>') | endif",
	group = augroup("checktime", { clear = true }),
})

-- Close the scratch preview automatically
autocmd({ "CursorMovedI", "InsertLeave" }, {
	desc = "Close the popup-menu automatically",
	pattern = "*",
	command = "if pumvisible() == 0 && !&pvw && getcmdwintype() == ''|pclose|endif",
	group = augroup("close_popup", { clear = true }),
})

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
