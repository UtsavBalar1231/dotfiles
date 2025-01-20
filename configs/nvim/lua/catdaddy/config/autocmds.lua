local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

-- vim.api.nvim_set_hl(0, "URL", {
-- 	underline = true,
-- 	fg = "#7daea3",
-- 	cterm = {
-- 		underline = true,
-- 	},
-- 	ctermfg = 109,
-- })
-- 
-- autocmd({ "BufReadPost", "BufNewFile", "BufEnter", "WinEnter" }, {
-- 	group = augroup("URL", { clear = true }),
-- 	pattern = "*",
-- 	desc = "Highlight URLs",
-- 	callback = function()
-- 		vim.fn.matchadd("URL", Util.url.url_pattern)
-- 	end,
-- })

vim.on_key(function(char)
	if vim.fn.mode() == "n" then
		local hlsearch_active = vim.tbl_contains({ "<CR>", "n", "N", "*", "#", "?", "/" }, vim.fn.keytrans(char))
		vim.opt.hlsearch = hlsearch_active
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

autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
	group = augroup("checktime", { clear = true }),
	pattern = "*",
	callback = function()
		if vim.o.buftype ~= "nofile" then
			vim.cmd("checktime")
		end
	end,
	desc = "Check time on FocusGained, TermClose, TermLeave",
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
