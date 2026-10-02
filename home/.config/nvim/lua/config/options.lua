-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

local g = vim.g
local opt = vim.opt
local o = vim.o

-- Set ZSH as default global shell
g.shell = "/usr/bin/zsh"

-- Enable undo dir setup
o.undodir = vim.fn.expand("~/.vimdid")
o.undofile = true

--- CRITICAL: Hard tabs setup (non-standard) ---
-- Do not use spaces for tabs
o.expandtab = false
-- Shift 4 spaces when tab
o.shiftwidth = 4
-- 1 tab == 4 spaces
o.tabstop = 4
o.softtabstop = 4
-- Enable auto indentation
o.autoindent = true
o.smartindent = true
o.smarttab = true
o.copyindent = true
o.preserveindent = true

--- Grep setup (ripgrep/ag/ack with fallbacks) ---
if vim.fn.executable("rg") == 1 then
	o.grepprg = "rg --vimgrep --no-heading --smart-case"
	o.grepformat = "%f:%l:%c:%m,%f:%l:%m"
elseif vim.fn.executable("ag") == 1 then
	o.grepprg = "ag --vimgrep"
	o.grepformat = "%f:%l:%c:%m"
elseif vim.fn.executable("ack") == 1 then
	o.grepprg = "ack --nogroup --nocolor"
elseif vim.fn.finddir(".git", ".;") ~= "" then
	o.grepprg = "git --no-pager grep --no-color -n"
	o.grepformat = "%f:%l:%m,%m %f match%ts,%f"
else
	o.grepprg = "grep -nIR $* /dev/null"
end

--- UI customizations ---
-- Custom fillchars (heavy borders)
opt.fillchars = {
	horiz = "━",
	horizup = "┻",
	horizdown = "┳",
	vert = "┃",
	vertleft = "┫",
	vertright = "┣",
	verthoriz = "╋",
	fold = " ",
	diff = "╱",
	eob = " ",
	foldopen = "▾",
	foldclose = "▸",
	foldsep = " ",
	msgsep = "━",
}

-- Additional critical options
o.scrolloff = 4
o.updatetime = 200
o.colorcolumn = "80"
o.relativenumber = true
o.laststatus = 3 -- global statusline

-- Fold settings
o.foldmethod = "expr"
o.foldexpr = "v:lua.vim.treesitter.foldexpr()"
o.foldlevel = 99
o.foldcolumn = "1"

-- TTY-aware termguicolors
local is_tty = os.getenv("XDG_SESSION_TYPE") == "tty" and os.getenv("SSH_TTY") == ""
if is_tty then
	o.termguicolors = false
else
	o.termguicolors = true
end

-- Expand %% to current directory in command mode
vim.cmd.cabbr({ args = { "<expr>", "%%", "&filetype == 'oil' ? bufname('%')[6:] : expand('%:p:h')" } })

--- Formatting settings ---
-- Disable auto-formatting on save (keep manual formatting with <leader>cf)
vim.g.autoformat = false
