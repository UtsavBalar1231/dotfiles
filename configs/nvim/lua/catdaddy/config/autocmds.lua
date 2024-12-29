local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

-- URL Highlighting on startup
vim.on_key(function(char)
	if vim.fn.mode() == "n" then
		local new_hlsearch = vim.tbl_contains({ "<CR>", "n", "N", "*", "#", "?", "/" }, vim.fn.keytrans(char))
		if vim.opt.hls:get() ~= new_hlsearch then
			vim.opt.hlsearch = new_hlsearch
		end
	end
end, vim.api.nvim_create_namespace("auto_hlsearch"))

autocmd({ "VimEnter", "FileType", "BufEnter", "WinEnter" }, {
	desc = "URL Highlighting",
	group = augroup("HighlightURL", { clear = true }),
	pattern = "*",
	callback = function()
		vim.api.nvim_set_hl(0, "URL", { link = "Underlined" })
	end,
})

-- Close some windows with q
autocmd("FileType", {
	desc = "Make q close help, man, quickfix, dap floats",
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
			end, {
				buffer = event.buf,
				silent = true,
				desc = "Quit buffer",
			})
		end)
	end,
})

-- make it easier to close man-files when opened inline
autocmd("FileType", {
	desc = "Make q close man-files",
	group = augroup("man_unlisted", { clear = true }),
	pattern = { "man" },
	callback = function(event)
		vim.bo[event.buf].buflisted = false
	end,
})

-- Highlight on yank
augroup("YankHighlight", { clear = true })
autocmd("TextYankPost", {
	desc = "Highlight on yank",
	group = "YankHighlight",
	pattern = "*",
	callback = function()
		(vim.hl or vim.highlight).on_yank()
	end,
})

-- Remove whitespace on save
-- autocmd("BufWritePre", { pattern = "", command = ":%s/\\s\\+$//e" })

-- go to last loc when opening a buffer
autocmd("BufReadPost", {
	desc = "Go to last loc when opening a buffer",
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
})

-- Check if we need to reload the file when it changed
autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
	desc = "Reload file if changed",
	group = augroup("checktime", { clear = true }),
	pattern = "*",
	callback = function()
		if vim.o.buftype ~= "nofile" then
			vim.cmd("checktime")
		end
	end,
})

-- resize splits if window got resized
autocmd({ "VimResized" }, {
	desc = "Resize splits if window got resized",
	group = augroup("resize_splits", { clear = true }),
	pattern = "*",
	callback = function()
		local current_tab = vim.fn.tabpagenr()
		vim.cmd("tabdo wincmd =")
		vim.cmd("tabnext " .. current_tab)
	end,
})

-- wrap and check for spell in text filetypes
autocmd("FileType", {
	group = augroup("wrap_spell", { clear = true }),
	pattern = { "text", "plaintex", "typst", "gitcommit", "markdown" },
	callback = function()
		vim.opt_local.wrap = true
		vim.opt_local.spell = true
	end,
})

-- Auto create dir when saving a file, in case some intermediate directory does not exist
autocmd({ "BufWritePre" }, {
	group = augroup("auto_create_dir", { clear = true }),
	callback = function(event)
		if event.match:match("^%w%w+:[\\/][\\/]") then
			return
		end
		---@diagnostic disable: undefined-field
		local file = vim.uv.fs_realpath(event.match) or event.match
		vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
	end,
})

-- Set filetype for bigfiles
vim.filetype.add({
	pattern = {
		[".*"] = {
			function(path, buf)
				return vim.bo[buf]
						and vim.bo[buf].filetype ~= "bigfile"
						and path
						and vim.fn.getfsize(path) > vim.g.bigfile_size
						and "bigfile"
					or nil
			end,
		},
	},
})

-- Configure some editor settings for terminal buffer
autocmd({ "TermOpen" }, {
	group = augroup("terminal", { clear = true }),
	callback = function()
		vim.opt_local.number = false
		vim.opt_local.relativenumber = false
		vim.opt_local.signcolumn = "no"
		vim.opt_local.spell = false
		vim.opt_local.wrap = true
		vim.opt_local.foldcolumn = "0"
	end,
})

autocmd({ "BufEnter", "CursorMoved", "CursorHoldI" }, {
	callback = function()
		local win_h = vim.api.nvim_win_get_height(0) -- height of window
		local off = math.min(vim.o.scrolloff, math.floor(win_h / 2)) -- scroll offset
		local dist = vim.fn.line("$") - vim.fn.line(".") -- distance from current line to last line
		local rem = vim.fn.line("w$") - vim.fn.line("w0") + 1 -- num visible lines in current window

		if dist < off and win_h - rem + dist < off then
			local view = vim.fn.winsaveview()
			view.topline = view.topline + off - (win_h - rem + dist)
			vim.fn.winrestview(view)
		end
	end,
	desc = "When at eob, bring the current line towards center screen",
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

-- https://github.com/chrisgrieser/.config/blob/88eb71f88528f1b5a20b66fd3dfc1f7bd42b408a/nvim/lua/config/keybindings.lua#L288
autocmd("FileType", {
	pattern = "qf",
	callback = function(event)
		vim.keymap.set("n", "dd", function()
			local qf_items = vim.fn.getqflist()
			local lnum = vim.api.nvim_win_get_cursor(0)[1]
			table.remove(qf_items, lnum)
			vim.fn.setqflist(qf_items, "r")
			vim.api.nvim_win_set_cursor(0, { lnum, 0 })
		end, { buffer = event.buf, silent = true, desc = "Remove quickfix entry" })
	end,
})

-- work-around for zsh-vi-mode/fish_vi_key_bindings auto insert
if vim.o.shell:find("zsh") or vim.o.shell:find("fish") then
	autocmd("TermEnter", {
		group = vim.api.nvim_create_augroup("shell_vi_mode", {}),
		pattern = "term://*" .. vim.o.shell,
		desc = "Enter insert mode of zsh-vi-mode or fish_vi_key_bindings",
		callback = function(event)
			if vim.bo[event.buf].filetype ~= "snacks_terminal" then
				return
			end
			vim.schedule(function()
				-- powerlevel10k for zsh-vi-mode or starship for fish_vi_key_bindings
				if vim.api.nvim_get_current_line():match("^❮ .*") then
					-- use `a` instead of `i` to restore cursor position
					vim.api.nvim_feedkeys(vim.keycode("a"), "n", false)
				end
			end)
		end,
	})
end
