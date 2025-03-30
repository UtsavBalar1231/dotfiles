local keymap = vim.api.nvim_set_keymap
local map = vim.keymap.set

-- better up/down
map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
map({ "n", "x" }, "<Down>", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })
map({ "n", "x" }, "<Up>", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })

-- Split windows
map("n", "<leader>-", "<C-W>s", { desc = "Split Window Below", remap = true })
map("n", "<leader>|", "<C-W>v", { desc = "Split Window Right", remap = true })

-- Move to window using the <ctrl> hjkl keys
map("n", "<C-h>", "<C-w>h", { desc = "Go to Left Window", remap = true })
map("n", "<C-j>", "<C-w>j", { desc = "Go to Lower Window", remap = true })
map("n", "<C-k>", "<C-w>k", { desc = "Go to Upper Window", remap = true })
map("n", "<C-l>", "<C-w>l", { desc = "Go to Right Window", remap = true })

-- Resize window using <ctrl> arrow keys
map("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase Window Height" })
map("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease Window Height" })
map("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease Window Width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase Window Width" })

-- Map <leader>w to quick save
map({ "x", "n", "s" }, "<leader>w", "<cmd>:w<cr><esc>", { desc = "Quick Save File" })

-- Map :wq to :x to save and close
-- map("n", ":wq", ":x", { desc = "Save and Close" })

-- tabs
map("n", "<leader><tab>l", "<cmd>tablast<cr>", { desc = "Last Tab" })
map("n", "<leader><tab>o", "<cmd>tabonly<cr>", { desc = "Close Other Tabs" })
map("n", "<leader><tab>f", "<cmd>tabfirst<cr>", { desc = "First Tab" })
map("n", "<leader><tab><tab>", "<cmd>tabnew<cr>", { desc = "New Tab" })
map("n", "<leader><tab>]", "<cmd>tabnext<cr>", { desc = "Next Tab" })
map("n", "<leader><tab>d", "<cmd>tabclose<cr>", { desc = "Close Tab" })
map("n", "<leader><tab>[", "<cmd>tabprevious<cr>", { desc = "Previous Tab" })

-- Map <leader>Q to quick quit all
keymap("n", "<leader>Q", "<cmd>:qa<cr>", { noremap = true, silent = true, desc = "Quick Quit All" })

-- Map <leader>sw to save and source
-- keymap("n", "<leader>ss", "<cmd>:w<cr>:source %<cr>", { noremap = true, silent = true, desc = "Save and Source" })

-- Use Q to quit
keymap("n", "Q", "<cmd>:q<cr>", { noremap = true, silent = true, desc = "Quit" })

-- Use W to write bang
keymap("n", "W", "<cmd>:w<cr>", { noremap = true, silent = true, desc = "Write" })

-- Centered search results
keymap("n", "n", "nzz", { noremap = true, silent = true, desc = "Centered Search Next" })
keymap("n", "N", "Nzz", { noremap = true, silent = true, desc = "Centered Search Previous" })
keymap("n", "*", "*zz", { noremap = true, silent = true, desc = "Centered Search *" })
keymap("n", "#", "#zz", { noremap = true, silent = true, desc = "Centered Search #" })
keymap("n", "g*", "g*zz", { noremap = true, silent = true, desc = "Centered Search g*" })
keymap("n", "g#", "g#zz", { noremap = true, silent = true, desc = "Centered Search g#" })

-- https://github.com/mhinz/vim-galore#saner-behavior-of-n-and-n
keymap("n", "n", "'Nn'[v:searchforward].'zv'", { expr = true, desc = "Next Search Result" })
keymap("x", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next Search Result" })
keymap("o", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next Search Result" })
keymap("n", "N", "'nN'[v:searchforward].'zv'", { expr = true, desc = "Previous Search Result" })
keymap("x", "N", "'nN'[v:searchforward]", { expr = true, desc = "Previous Search Result" })
keymap("o", "N", "'nN'[v:searchforward]", { expr = true, desc = "Previous Search Result" })

-- Ctrl+j and Ctrl+k as Esc
keymap("n", "<C-j>", "<Esc>", { noremap = true, silent = true, desc = "Escape" })
keymap("i", "<C-k>", "<Esc>", { noremap = true, silent = true, desc = "Escape" })
keymap("v", "<C-j>", "<Esc>", { noremap = true, silent = true, desc = "Escape" })
keymap("s", "<C-k>", "<Esc>", { noremap = true, silent = true, desc = "Escape" })
keymap("x", "<C-j>", "<Esc>", { noremap = true, silent = true, desc = "Escape" })
keymap("c", "<C-j>", "<Esc>", { noremap = true, silent = true, desc = "Escape" })
keymap("o", "<C-j>", "<Esc>", { noremap = true, silent = true, desc = "Escape" })
keymap("t", "<C-k>", "<Esc>", { noremap = true, silent = true, desc = "Escape" })

-- Clear search and stop snippet on escape
map({ "i", "n", "s" }, "<esc>", function()
	vim.cmd("noh")
	return "<esc>"
end, { expr = true, desc = "Escape and Clear hlsearch" })

-- Clear search, diff update and redraw
-- taken from runtime/lua/_editor.lua
map(
	"n",
	"<leader>ur",
	"<Cmd>nohlsearch<Bar>diffupdate<Bar>normal! <C-L><CR>",
	{ desc = "Redraw / Clear hlsearch / Diff Update" }
)
-- Jump to the end of the line with L
keymap("n", "L", "$", { noremap = true, silent = true, desc = "Jump to End of Line" })

-- Jump to the beginning of the line with H
keymap("n", "H", "^", { noremap = true, silent = true, desc = "Jump to Beginning of Line" })

-- Remap <C-a> to select all
keymap("n", "<C-a>", "ggVG", { noremap = true, silent = true, desc = "Select All" })

-- Proper X clipboard support
keymap("n", "<leader>y", '"+y', { noremap = true, silent = true, desc = "Copy to Clipboard" })
keymap("v", "<leader>y", '"+y', { noremap = true, silent = true, desc = "Copy to Clipboard" })
keymap("n", "<leader>p", '"+p', { noremap = true, silent = true, desc = "Paste from Clipboard" })
keymap("v", "<leader>p", '"+p', { noremap = true, silent = true, desc = "Paste from Clipboard" })

-- Left and right arrow keys to move between buffers
keymap("n", "<Left>", "<cmd>:bprevious<cr>", { noremap = true, silent = true, desc = "Previous Buffer" })
keymap("n", "<Right>", "<cmd>:bnext<cr>", { noremap = true, silent = true, desc = "Next Buffer" })
-- Swift navigation between buffers with leader + leader
-- keymap("n", "<leader><leader>", "<cmd>:b#<cr>", { noremap = true, silent = true, desc = "Previous Buffer" })

-- Hide or Show the invisible characters
keymap("n", "<leader>,", "<cmd>:set list!<cr>", { noremap = true, silent = true, desc = "Toggle Invisible Characters" })

-- <leader>x to chmod +x the current file
keymap("n", "<leader>xx", "<cmd>!chmod +x %<cr>", { noremap = true, silent = true, desc = "Make File Executable" })

-- Keybindings for moving lines in normal mode
keymap("n", "<A-j>", "<cmd>:m .+1<cr>==", { noremap = true, silent = true, desc = "Move Line Down" })
keymap("n", "<A-k>", "<cmd>:m .-2<cr>==", { noremap = true, silent = true, desc = "Move Line Up" })
keymap("n", "<A-Down>", "<cmd>:m .+1<cr>==", { noremap = true, silent = true, desc = "Move Line Down" })
keymap("n", "<A-Up>", "<cmd>:m .-2<cr>==", { noremap = true, silent = true, desc = "Move Line Up" })

-- Keybindings for moving lines in insert mode
keymap("i", "<A-j>", "<Esc>:m .+1<cr>==gi", { noremap = true, silent = true, desc = "Move Line Down" })
keymap("i", "<A-k>", "<Esc>:m .-2<cr>==gi", { noremap = true, silent = true, desc = "Move Line Up" })
keymap("i", "<A-Down>", "<Esc>:m .+1<cr>==gi", { noremap = true, silent = true, desc = "Move Line Down" })
keymap("i", "<A-Up>", "<Esc>:m .-2<cr>==gi", { noremap = true, silent = true, desc = "Move Line Up" })

-- Keybindings for moving lines in visual mode
keymap("x", "<A-j>", "<cmd>:m '>+1<cr>gv=gv", { noremap = true, silent = true, desc = "Move Line Down" })
keymap("x", "<A-k>", "<cmd>:m '<-2<cr>gv=gv", { noremap = true, silent = true, desc = "Move Line Up" })
keymap("x", "<A-Down>", "<cmd>:m '>+1<cr>gv=gv", { noremap = true, silent = true, desc = "Move Line Down" })
keymap("x", "<A-Up>", "<cmd>:m '<-2<cr>gv=gv", { noremap = true, silent = true, desc = "Move Line Up" })

-- Update and install plugins
keymap("n", "<leader>uu", "<cmd>:Lazy sync<cr>", { noremap = true, silent = true, desc = "Packer Sync" })

-- Delete a buffer with the window
keymap("n", "<leader>dd", "<cmd>:bd<cr>", { noremap = true, silent = true, desc = "Delete Buffer" })

-- LSP code formatting
keymap(
	"n",
	"<leader>F",
	"<cmd>lua vim.lsp.buf.format { async = true } <cr>",
	{ noremap = true, silent = true, desc = "LSP Format" }
)
keymap(
	"v",
	"<Leader>1f",
	"<cmd>lua vim.lsp.buf.format { async = true } <cr>",
	{ noremap = true, silent = true, desc = "LSP Format" }
)

-- -- Map ss to split the current window horizontally
-- keymap("n", "sw", "<cmd>:split<cr><C-w>w", { noremap = true, silent = true, desc = "Horizontal Split" })
-- -- Map sv to split the current window vertically
-- keymap("n", "sv", "<cmd>:vsplit<cr><C-w>w", { noremap = true, silent = true, desc = "Vertical Split" })
-- -- Map sh to move to the left window
-- keymap("n", "sh", "<C-w>h", { noremap = true, silent = true, desc = "Move Left" })
-- -- Map sl to move to the right window
-- keymap("n", "sl", "<C-w>l", { noremap = true, silent = true, desc = "Move Right" })
-- -- Map sk to move to the top window
-- keymap("n", "sk", "<C-w>k", { noremap = true, silent = true, desc = "Move Up" })
-- -- Map sj to move to the bottom window
-- keymap("n", "sj", "<C-w>j", { noremap = true, silent = true, desc = "Move Down" })

-- Disable :help on <F1>
keymap("n", "<F1>", "<ESC>", { noremap = true, silent = true, desc = "Disable Help" })
keymap("i", "<F1>", "<ESC>", { noremap = true, silent = true, desc = "Disable Help" })

-- Set wq!! to write and quit with sudo permissions
keymap("c", "wq!!", "wq! !sudo tee > /dev/null %", { noremap = true, silent = true, desc = "Write and Quit with Sudo" })

-- better indenting
keymap("v", "<", "<gv", { noremap = true, silent = true, desc = "Better Indent" })
keymap("v", ">", ">gv", { noremap = true, silent = true, desc = "Better Indent" })

-- keymap to open lazy nvim
keymap("n", "<leader>l", "<cmd>Lazy<cr>", { noremap = true, silent = true, desc = "Lazy" })

-- keymap to open new file
keymap("n", "<leader>fn", "<cmd>enew<cr>", { noremap = true, silent = true, desc = "New File" })

-- location list
map("n", "<leader>xl", function()
	local success, err = pcall(vim.fn.getloclist(0, { winid = 0 }).winid ~= 0 and vim.cmd.lclose or vim.cmd.lopen)
	if not success and err then
		vim.notify(err, vim.log.levels.ERROR)
	end
end, { desc = "Location List" })
keymap("n", "[l", "lua vim.cmd.lprev()<cr>", { desc = "Previous loclist" })
keymap("n", "]l", "lua vim.cmd.lnext()<cr>", { desc = "Next loclist" })
keymap("n", "]L", "lua vim.cmd.lfirst()<cr>", { desc = "First loclist" })
keymap("n", "[L", "lua vim.cmd.llast()<cr>", { desc = "Last loclist" })

-- quickfix list
map("n", "<leader>xq", function()
	local success, err = pcall(vim.fn.getqflist({ winid = 0 }).winid ~= 0 and vim.cmd.cclose or vim.cmd.copen)
	if not success and err then
		vim.notify(err, vim.log.levels.ERROR)
	end
end, { desc = "Quickfix List" })
keymap("n", "[q", "lua vim.cmd.cprev()<cr>", { desc = "Previous Quickfix" })
keymap("n", "]q", "lua vim.cmd.cnext()<cr>", { desc = "Next Quickfix" })
keymap("n", "]Q", "lua vim.cmd.cfirst()<cr>", { desc = "First Quickfix" })
keymap("n", "[Q", "lua vim.cmd.clast()<cr>", { desc = "Last Quickfix" })


-- BASH-style movement in insert mode
keymap("i", "<C-a>", "<C-o>^", { noremap = true, silent = true, desc = "Move to Beginning of Line" })
keymap("i", "<C-e>", "<C-o>$", { noremap = true, silent = true, desc = "Move to End of Line" })
