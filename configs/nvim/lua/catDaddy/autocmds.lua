-- Create/get autocommand group
local augroup = vim.api.nvim_create_augroup
-- Create autocommand
local autocmd = vim.api.nvim_create_autocmd
local utils = require("catDaddy.utils")

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
		utils.set_url_match()
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
		"help",
		"lir",
		"lsp-installer",
		"lspinfo",
		"man",
		"notify",
		"null-ls-info",
		"qf",
		"tsplayground",
	},
	callback = function(event)
		vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true, nowait = true })
		vim.opt_local.buflisted = false
	end,
})

-- make it easier to close man-files when opened inline
autocmd("FileType", {
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
		vim.highlight.on_yank({ timeout = "400" })
	end,
})

-- Remove whitespace on save
-- autocmd("BufWritePre", { pattern = "", command = ":%s/\\s\\+$//e" })

-- Set completeopt to have a better completion experience
autocmd("InsertEnter", { pattern = "", command = "setlocal completeopt=menuone,noselect" })

-- Jump to last position when opening files
autocmd("BufReadPost", {
	pattern = "",
	command = [[if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g`\"" | endif]],
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

-- Auto create parent directory if needed
autocmd({ "BufWritePre" }, {
	group = augroup("auto_create_dirs", { clear = true }),
	pattern = "*",
	callback = function(event)
		vim.fn.mkdir(vim.fn.fnamemodify(vim.loop.fs_realpath(event.match) or event.match, ":p:h"), "p")
	end,
})

-- Auto create dir when saving a file, in case some intermediate directory does not exist
autocmd({ "BufWritePre" }, {
	group = augroup("auto_create_dir", { clear = true }),
	callback = function(event)
		if event.match:match("^%w%w+:[\\/][\\/]") then
			return
		end
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

-- Disable minianimate in bigfiles
autocmd({ "FileType" }, {
	group = augroup("bigfile", { clear = true }),
	pattern = "bigfile",
	callback = function(event)
		vim.b[event.buf].minianimate_disable = true
		vim.b[event.buf].cmp_enabled = false
		vim.b[event.buf].miniindentscope_disable = true
		vim.b[event.buf].matchup_matchparen_enabled = 0
		vim.opt_local.wrap = true
		vim.opt_local.list = false
		vim.schedule(function()
			vim.bo[event.buf].syntax = vim.filetype.match({ buf = event.buf }) or ""
		end)
	end,
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

