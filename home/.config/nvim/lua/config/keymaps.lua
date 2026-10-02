-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set

-- Quick quit with Q
map("n", "Q", "<cmd>q<cr>", { desc = "Quit" })

-- Quick write with W
map("n", "W", "<cmd>w<cr>", { desc = "Write" })

-- Jump to beginning/end of line with H/L
map("n", "H", "^", { desc = "Jump to Beginning of Line" })
map("n", "L", "$", { desc = "Jump to End of Line" })

-- Quick save with leader-w (in addition to W)
map({ "x", "n", "s" }, "<leader>w", "<cmd>w<cr><esc>", { desc = "Quick Save File" })

-- Make file executable with <leader>xx
map("n", "<leader>xx", "<cmd>!chmod +x %<cr>", { desc = "Make File Executable" })

-- LazyVim standard formatting
map({ "n", "x" }, "<leader>F", function()
	LazyVim.format({ force = true })
end, { desc = "Format" })

-- Toggle auto-formatting
map("n", "<leader>uf", function()
	LazyVim.format.toggle()
end, { desc = "Toggle Auto Format (Global)" })

map("n", "<leader>uF", function()
	LazyVim.format.toggle(true)
end, { desc = "Toggle Auto Format (Buffer)" })

-- Select all with <C-a>
map("n", "<C-a>", "ggVG", { desc = "Select All" })

-- System clipboard operations
map({ "n", "v" }, "<leader>y", '"+y', { desc = "Copy to Clipboard" })
map({ "n", "v" }, "<leader>p", '"+p', { desc = "Paste from Clipboard" })

-- Buffer navigation with arrow keys
map("n", "<Left>", "<cmd>bprevious<cr>", { desc = "Previous Buffer" })
map("n", "<Right>", "<cmd>bnext<cr>", { desc = "Next Buffer" })

-- Bash-style insert mode movement
map("i", "<C-a>", "<C-o>^", { desc = "Move to Beginning of Line" })
map("i", "<C-e>", "<C-o>$", { desc = "Move to End of Line" })

-- Centered search results
map("n", "*", "*zz", { desc = "Centered Search *" })
map("n", "#", "#zz", { desc = "Centered Search #" })
map("n", "g*", "g*zz", { desc = "Centered Search g*" })
map("n", "g#", "g#zz", { desc = "Centered Search g#" })

-- Better n/N search behavior (centered)
map("n", "n", "'Nn'[v:searchforward].'zv'", { expr = true, desc = "Next Search Result" })
map("x", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next Search Result" })
map("o", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next Search Result" })
map("n", "N", "'nN'[v:searchforward].'zv'", { expr = true, desc = "Previous Search Result" })
map("x", "N", "'nN'[v:searchforward]", { expr = true, desc = "Previous Search Result" })
map("o", "N", "'nN'[v:searchforward]", { expr = true, desc = "Previous Search Result" })

-- Undo break-points at punctuation
map("i", ",", ",<c-g>u")
map("i", ".", ".<c-g>u")
map("i", ";", ";<c-g>u")

-- Better indenting (keep selection)
map("v", "<", "<gv", { desc = "Better Indent Left" })
map("v", ">", ">gv", { desc = "Better Indent Right" })

-- Toggle invisible characters
map("n", "<leader>,", "<cmd>set list!<cr>", { desc = "Toggle Invisible Characters" })

-- Disable F1 help
map({ "n", "i" }, "<F1>", "<ESC>", { desc = "Disable Help" })
