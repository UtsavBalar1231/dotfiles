_G.Util = require("catdaddy.util")

require("catdaddy.config.lazy")
require("catdaddy.config.options")
require("catdaddy.config.autocmds")
require("catdaddy.config.keymaps")
require("catdaddy.config.cmd")

if vim.g.vscode then
	require("catdaddy.config.vscode")
end

if vim.g.neovide then
	require("catdaddy.config.neovide")
end
