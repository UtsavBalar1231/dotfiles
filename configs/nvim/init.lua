require("config.lazy")
require("config.cmd")
require("config.options")
require("config.keymaps")
require("config.autocmds")

-- Load colorscheme
local colorscheme_file = vim.fn.stdpath("config") .. "/colorscheme.lua"
if vim.fn.filereadable(colorscheme_file) == 1 then
	dofile(colorscheme_file)
else
	vim.cmd("colorscheme default")
end

-- Disable default colorschemes
vim.cmd([[source ~/.config/nvim/disable-default-colorschemes.vim]])
