local g = vim.g

-- Set ZSH as default global shell
---@diagnostic disable-next-line: inject-field
g.shell = "/usr/bin/zsh"

-- Map the leader key to space
---@diagnostic disable-next-line: inject-field
g.mapleader = " "

---@diagnostic disable-next-line: inject-field
g.maplocalleader = ","

-- Enable undo dir setup
vim.o.undodir = vim.fn.stdpath("config") .. "/../../.vimdid"
vim.o.undofile = true

-- Enable lazy redraw
vim.o.lazyredraw = true

--- Sane tabs setup ---
-- Do not use spaces for tabs
vim.o.expandtab = false
-- Shift 4 spaces when tab
vim.o.shiftwidth = 4
-- 1 tab == 4 spaces
vim.o.tabstop = 4
-- Enable auto indentation in vim
vim.o.autoindent = true
-- Autoindent new lines
vim.o.smartindent = true
-- Smart tab
vim.o.smarttab = true
-- Copy indent from current line
vim.o.copyindent = true
-- Preserve indent on next line
vim.o.preserveindent = true
--- Better search setup ---

-- Ignore case when searching
vim.o.ignorecase = true
-- But be smart about it
vim.o.smartcase = true
-- Highlight search results
vim.o.hlsearch = true
-- Incremental search
vim.o.incsearch = true
-- grep-like search
vim.o.gdefault = true
-- Grep setup
if vim.fn.executable("rg") == 1 then
	vim.o.grepprg = "rg --vimgrep --no-heading --smart-case"
	vim.o.grepformat = "%f:%l:%c:%m,%f:%l:%m"
elseif vim.fn.executable("ag") == 1 then
	vim.o.grepprg = "ag --vimgrep"
	vim.o.grepformat = "%f:%l:%c:%m"
elseif vim.fn.executable("ack") == 1 then
	vim.o.grepprg = "ack --nogroup --nocolor"
elseif vim.fn.finddir(".git", ".;") ~= "" then
	vim.o.grepprg = "git --no-pager grep --no-color -n"
	vim.o.grepformat = "%f:%l:%m,%m %f match%ts,%f"
else
	vim.o.grepprg = "grep -nIR $* /dev/null"
end

-- infer cases in keyword completion
vim.o.infercase = true

--- General editor settings ---
---@diagnostic disable-next-line: undefined-field
vim.o.timeoutlen = vim.g.vscode and 1000 or 300
-- Set default encoding
vim.o.encoding = "utf-8"
-- Default scrolloff in vim
vim.o.scrolloff = 4
-- Enable auto write
vim.o.autowrite = true
-- Enable mouse support
vim.o.mouse = "a"
-- Copy/paste to system clipboard
vim.o.clipboard = vim.env.SSH_TTY and "" or "unnamedplus"
-- Autocomplete options
vim.o.completeopt = "menu,menuone,noselect" -- Converted table to string
-- Hide * markup for bold and italic, but not markers with substitutions
vim.o.conceallevel = 2
--- Jump options
vim.o.jumpoptions = "view"
-- Save swap file and trigger CursorHold
vim.o.updatetime = 250
-- Do not save backup
vim.o.writebackup = false
-- Set fillchars
vim.opt.fillchars = {
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
vim.o.foldcolumn = "1"
vim.o.foldlevel = 99

vim.o.cmdwinheight = 30
vim.o.colorcolumn = "+0"
vim.o.confirm = true
vim.o.fileignorecase = true
--- General editor UI setup ---

-- Show line number
vim.o.number = true
-- Enable relative line numbers
vim.o.relativenumber = true
-- Disable the default ruler
vim.o.ruler = false
vim.opt.sessionoptions = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp", "folds" }
-- Highlight matching parenthesis
vim.o.showmatch = true
-- Line length marker at 120 columns
vim.o.colorcolumn = "80"
-- Vertical split to the right
vim.o.splitright = true
-- Horizontal split to the bottom
vim.o.splitbelow = true
-- Keep windows equal when splitting
vim.o.equalalways = true
-- Ignore case letters when search
vim.o.ignorecase = true
-- allow cursor to wrap to next/prev line
vim.o.whichwrap = "h,l"
-- Ignore lowercase for the whole pattern
vim.o.smartcase = true
-- Wrap on word boundary
vim.o.linebreak = true

local is_tty = os.getenv("XDG_SESSION_TYPE") == "tty" and os.getenv("SSH_TTY") == ""
if is_tty then
	vim.o.termguicolors = false
else
	-- Enable 24-bit RGB colors
	vim.o.termguicolors = true
end
-- Set global statusline
vim.o.laststatus = 3
-- allow backspace on indent, end of line or insert mode start position
vim.o.backspace = "indent,eol,start"
-- Enable ttyfast
vim.o.ttyfast = true
-- Show (partial) command in status line
vim.o.showcmd = true
-- No show mode
vim.o.showmode = false
-- Show nbsp, extends, precedes and trailing spaces
vim.o.list = false
vim.o.listchars = "nbsp:¬,extends:»,precedes:«,trail:•,tab:»·"
-- Better display for messages
vim.o.cmdheight = 1
-- Show cursor line
vim.o.cursorline = true
-- Popup blend
vim.o.pumblend = 0
-- Maximum number of entries in a popup
vim.o.pumheight = 10
-- Round indent
vim.o.shiftround = true
-- Columns of context
vim.o.sidescrolloff = 8
-- Always show the signcolumn, otherwise it would shift the text each time
vim.o.signcolumn = "yes"
-- Allow cursor to move where there is no text in visual block mode
vim.o.virtualedit = "block"
-- Enable line wrap
vim.o.wrap = true
-- turn off swapfile
vim.o.swapfile = false
-- Emoji support
vim.o.emoji = true
-- Disable modeline
vim.o.modeline = false
vim.o.modelines = 0
--- Format options setup ---

vim.o.formatoptions = "jcroqlnt"
vim.opt.diffopt = {
	"filler",
	"indent-heuristic",
	"linematch:60",
	"vertical",
}

--- Incremental live completion
vim.o.inccommand = "nosplit"

-- Show short messages
vim.opt.shortmess:append("C") -- for completion messages
vim.opt.shortmess:append("c") -- for completion messages
vim.opt.shortmess:append("I") -- Hide the startup screen
vim.opt.shortmess:append("s") -- Do not show search count
-- vim.opt.shortmess:append("A") -- Ignore swap file messages
-- vim.opt.shortmess:append("a") -- Shorter message formats

-- built-in ftplugins should not change my keybindings
vim.g.no_plugin_maps = true
vim.cmd.filetype({ args = { "plugin", "on" } })
vim.cmd.filetype({ args = { "plugin", "indent", "on" } })

-- Enable spell checking
vim.o.spelllang = "en" -- Converted table to string
vim.opt.spelloptions:append("noplainbuffer")

if vim.fn.has("nvim-0.10") == 1 then
	vim.o.smoothscroll = true
	vim.o.foldmethod = "expr"
	vim.o.foldtext = ""
else
	vim.o.foldmethod = "indent"
end

-- Fix markdown indentation settings
g.markdown_recommended_style = 0

-- disable some default providers
g.loaded_node_provider = 0
g.loaded_python3_provider = 0
g.loaded_perl_provider = 0
g.loaded_ruby_provider = 0

vim.opt.viewoptions = {
	"cursor",
	"folds",
}

vim.o.wildmenu = true
vim.o.wildmode = "longest,list,full"
vim.o.wildoptions = "pum"
vim.opt.wildignore:append({
	".git/",
	".hg/",
	".svn/",
	".DS_Store",
	".pyc",
	".pyo",
	".rbc",
	".rbo",
	".class",
	".o",
	".so",
	".cache",
	"~",
	".swp",
	".png",
	".jpg",
	".jpeg",
	".gif",
	".wav",
	"*.aiff",
})

-- if the completion engine supports the AI source,
-- use that instead of inline suggestions
vim.g.ai_cmp = true

-- Expand %% to current directory in command mode
vim.cmd.cabbr({ args = { "<expr>", "%%", "&filetype == 'oil' ? bufname('%')[6:] : expand('%:p:h')" } })
