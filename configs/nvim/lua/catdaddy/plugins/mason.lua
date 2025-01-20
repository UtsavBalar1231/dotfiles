return {
	"williamboman/mason.nvim",
	dependencies = {
		"williamboman/mason-lspconfig.nvim",
		"WhoIsSethDaniel/mason-tool-installer.nvim",
	},

	config = function()
		local mason = require("mason")
		local mason_lspconfig = require("mason-lspconfig")
		local mason_tool_installer = require("mason-tool-installer")

		-- enable mason and configure icons
		mason.setup({
			ui = {
				icons = {
					package_installed = "",
					package_pending = "",
					package_uninstalled = "",
				},
			},
		})

		mason_lspconfig.setup({
			-- list of servers for mason to install
			ensure_installed = {
				"asm_lsp",
				"bashls",
				"clangd",
				"cssls",
				"esbonio",
				"html",
				"jsonls",
				"lua_ls",
				"pyright",
				"rust_analyzer",
				"vimls",
				"yamlls",
			},
			automatic_installation = true,
		})

		mason_tool_installer.setup({
			ensure_installed = {
				"black",
				"clang-format",
				"clangd",
				"esbonio",
				"eslint",
				"eslint_d",
				"html",
				"marksman",
				"mdformat",
				"prettier",
				"prettierd",
				"pylint",
				"pyright",
				"rust_analyzer",
				"stylelint",
				"stylua",
				"yamlfmt",
				"yamllint",
			},
		})
	end,
}
