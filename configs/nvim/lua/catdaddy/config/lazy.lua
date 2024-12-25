-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
---@diagnostic disable-next-line: undefined-field
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
	if vim.v.shell_error ~= 0 then
		vim.api.nvim_echo({
			{ "Failed to clone lazy.nvim:\n", "ErrorMsg" },
			{ out, "WarningMsg" },
			{ "\nPress any key to exit..." },
		}, true, {})
		vim.fn.getchar()
		os.exit(1)
	end
end
vim.opt.rtp:prepend(lazypath)

vim.g.mapleader = " "
vim.g.maplocalleader = ","

-- Setup lazy.nvim
require("lazy").setup({
	change_detection = { enabled = false },
	spec = {
		{ import = "catdaddy.plugins" },
	},
	defaults = { lazy = true },
	install = {},
	checker = {
		enabled = true,
		notify = false,
	},
	performance = {
		cache = {
			enabled = true,
		},
		rtp = {
			-- disable some rtp plugins
			disabled_plugins = {
				"gzip",
				-- "matchit",
				-- "matchparen",
				"netrwPlugin",
				"rplugin",
				"tarPlugin",
				"tohtml",
				"tutor",
				"zipPlugin",
			},
		},
	},
	debug = false,
	profiling = {
		loader = false,
		require = false,
	},
})

-- List of default Vim colorschemes to disable
local disabled_colorschemes = {
	"blue.vim",
	"darkblue.vim",
	"delek.vim",
	"desert.vim",
	"elflord.vim",
	"evening.vim",
	"industry.vim",
	"koehler.vim",
	"lunaperche.vim",
	"morning.vim",
	"murphy.vim",
	"pablo.vim",
	"peachpuff.vim",
	"quiet.vim",
	"retrobox.vim",
	"ron.vim",
	"shine.vim",
	"slate.vim",
	"sorbet.vim",
	"torte.vim",
	"wildcharm.vim",
	"zaibatsu.vim",
	"zellner.vim",
	"modus",
	"kanagawa",
}

require("catdaddy.util").colorscheme.disable_colorschemes(disabled_colorschemes)
require("catdaddy.util").colorscheme.load_colorscheme()
