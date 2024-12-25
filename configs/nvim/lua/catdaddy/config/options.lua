local g = vim.g
local opt = vim.opt

-- Set ZSH as default global shell
---@diagnostic disable-next-line: inject-field
g.shell = "/usr/bin/zsh"

-- Map the leader key to space
---@diagnostic disable-next-line: inject-field
g.mapleader = " "

---@diagnostic disable-next-line: inject-field
g.maplocalleader = ","

-- Set bigfile size
---@diagnostic disable-next-line: inject-field
g.bigfile_size = 1024 * 256

-- Enable undo dir setup
opt.undodir = vim.fn.stdpath("config") .. "/../../.vimdid"
opt.undofile = true

-- Enable lazy redraw
opt.lazyredraw = true

-----------------------
--- Sane tabs setup ---
-----------------------
-- Do not use spaces for tabs
opt.expandtab = false
-- Shift 4 spaces when tab
opt.shiftwidth = 4
-- 1 tab == 4 spaces
opt.tabstop = 4
-- Enable auto indentation in vim
opt.autoindent = true
-- Autoindent new lines
opt.smartindent = true
-- Smart tab
opt.smarttab = true
-- Copy indent from current line
opt.copyindent = true
-- Preserve indent on next line
opt.preserveindent = true

---------------------------
--- Better search setup ---
---------------------------
-- Ignore case when searching
opt.ignorecase = true
-- But be smart about it
opt.smartcase = true
-- Highlight search results
opt.hlsearch = true
-- Incremental search
opt.incsearch = true
-- grep-like search
opt.gdefault = true
--- Grep setup
opt.grepformat = "%f:%l:%c:%m"
opt.grepprg = "rg --vimgrep"
-- infer cases in keyword completion
opt.infercase = true

opt.guicursor = {
	"n-sm:block",
	"v:hor50",
	"c-ci-cr-i-ve:ver10",
	"o-r:hor10",
	"a:Cursor/Cursor-blinkwait1-blinkon1-blinkoff1",
}

-------------------------------
--- General editor settings ---
-------------------------------
---@diagnostic disable-next-line: undefined-field
opt.timeoutlen = vim.g.vscode and 1000 or 300
-- Set default encoding
opt.encoding = "utf-8"
-- Default scrolloff in vim
opt.scrolloff = 4
-- Enable auto write
opt.autowrite = true
-- Enable mouse support
opt.mouse = "a"
-- Copy/paste to system clipboard
opt.clipboard = vim.env.SSH_TTY and "" or "unnamedplus"
-- Autocomplete options
opt.completeopt = { "menu", "menuone", "noselect" }
-- Hide * markup for bold and italic, but not markers with substitutions
opt.conceallevel = 2
--- Jump options
opt.jumpoptions = "view"
-- Save swap file and trigger CursorHold
opt.updatetime = 250
-- Do not save backup
opt.writebackup = false
-- Set fillchars
opt.fillchars = {
	diff = "╱",
	eob = " ",
	fold = " ",
	foldclose = "",
	foldopen = "",
	foldsep = " ",
	horiz = "━",
	horizdown = "┳",
	horizup = "┻",
	msgsep = "━",
	vert = "┃",
	verthoriz = "╋",
	vertleft = "┫",
	vertright = "┣",
}

-- Fold settings
opt.foldcolumn = "1"
opt.foldlevel = 99
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldmethod = "expr"

--opt.cmdwinheight = 30
--opt.colorcolumn = "+0"
--opt.confirm = true
--opt.fileignorecase = true

-------------------------------
--- General editor UI setup ---
-------------------------------
-- Show line number
opt.number = true
-- Enable relative line numbers
opt.relativenumber = true
-- Disable the default ruler
opt.ruler = false
opt.sessionoptions = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp", "folds" }
-- Highlight matching parenthesis
opt.showmatch = true
-- Line length marker at 120 columns
opt.colorcolumn = "80"
-- Vertical split to the right
opt.splitright = true
-- Horizontal split to the bottom
opt.splitbelow = true
-- Keep same window when splitting
opt.splitkeep = "screen"
-- Keep windows equal when splitting
opt.equalalways = true
-- Put new windows right of current
opt.splitright = true
-- Ignore case letters when search
opt.ignorecase = true
-- Ignore lowercase for the whole pattern
opt.smartcase = true
-- Wrap on word boundary
opt.linebreak = true
-- Enable 24-bit RGB colors
opt.termguicolors = true
-- Set global statusline
opt.laststatus = 3
-- allow backspace on indent, end of line or insert mode start position
opt.backspace = "indent,eol,start"
-- Enable ttyfast
opt.ttyfast = true
-- Show (partial) command in status line
opt.showcmd = true
-- No show mode
opt.showmode = false
-- Show nbsp, extends, precedes and trailing spaces
opt.list = false
opt.listchars = "nbsp:¬,extends:»,precedes:«,trail:•"
-- Better display for messages
opt.cmdheight = 1
-- Show cursor line
opt.cursorline = true
-- Popup blend
opt.pumblend = 0
-- Maximum number of entries in a popup
opt.pumheight = 10
-- Round indent
opt.shiftround = true
-- Columns of context
opt.sidescrolloff = 8
-- Always show the signcolumn, otherwise it would shift the text each time
opt.signcolumn = "yes"
-- Allow cursor to move where there is no text in visual block mode
opt.virtualedit = "block"
-- Enable line wrap
opt.wrap = true
-- turn off swapfile
opt.swapfile = false
-- Emoji support
opt.emoji = true
-- Disable modeline
opt.modeline = false
opt.modelines = 0
----------------------------
--- Format options setup ---
----------------------------
opt.formatoptions = "jcroqlnt" -- tcqj
opt.diffopt = {
	"filler",
	"indent-heuristic",
	"linematch:60",
	"vertical",
}

--- Incremental live completion
opt.inccommand = "nosplit"

-- Show short messages
opt.shortmess = "acstFOSW"

-- Enable spell checking
opt.spelllang = { "en" }
opt.spelloptions:append("noplainbuffer")

if vim.fn.has("nvim-0.10") == 1 then
	opt.smoothscroll = true
	opt.foldmethod = "expr"
	opt.foldtext = ""
else
	opt.foldmethod = "indent"
end

-- Fix markdown indentation settings
g.markdown_recommended_style = 0

-- disable some default providers
g.loaded_node_provider = 0
g.loaded_python3_provider = 0
g.loaded_perl_provider = 0
g.loaded_ruby_provider = 0

opt.viewoptions = {
	"cursor",
	"folds",
}

-- opt.wildignore = {
-- 	".git/*",
-- 	".hg/*",
-- 	".svn/*",
-- 	".DS_Store",
-- 	"*.pyc",
-- 	"*.pyo",
-- 	"*.rbc",
-- 	"*.rbo",
-- 	"*.class",
-- 	"*.o",
-- 	"*.so",
-- 	"*.cache",
-- 	"*~",
-- 	"*.swp",
-- }
-- opt.wildmode = "longest:full"
-- opt.wildoptions = "pum"
