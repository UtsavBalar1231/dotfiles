return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPost", "BufNewFile", "BufWritePre" },
	enabled = not vim.g.vscode,
	dependencies = {
		"saghen/blink.cmp",
	},
	config = function()
		local lspconfig = require("lspconfig")

		local keymap = vim.keymap
		local opts = { noremap = true, silent = true }

		local on_attach = function(client, bufnr)
			-- Uncomment code below to enable inlay hint from language server, some LSP server supports inlay hint,
			-- but disable this feature by default, so you may need to enable inlay hint in the LSP server config.
			-- vim.lsp.inlay_hint.enable(true, {buffer=bufnr})

			-- The below command will highlight the current variable and its usages in the buffer.
			if client.server_capabilities.documentHighlightProvider then
				vim.cmd([[
      				hi! link LspReferenceRead Visual
      				hi! link LspReferenceText Visual
      				hi! link LspReferenceWrite Visual
    			]])

				local gid = vim.api.nvim_create_augroup("lsp_document_highlight", { clear = true })
				vim.api.nvim_create_autocmd("CursorHold", {
					group = gid,
					buffer = bufnr,
					callback = function()
						vim.lsp.buf.document_highlight()
					end,
				})

				vim.api.nvim_create_autocmd("CursorMoved", {
					group = gid,
					buffer = bufnr,
					callback = function()
						vim.lsp.buf.clear_references()
					end,
				})
			end

			opts.buffer = bufnr
			-- set keybinds
			opts.desc = "LSP: Show references"
			keymap.set("n", "gR", "<cmd>Telescope lsp_references<CR>", opts) -- show definition, references

			opts.desc = "LSP: Go to declaration"
			keymap.set("n", "gD", vim.lsp.buf.declaration, opts) -- go to declaration

			opts.desc = "LSP: Show definitions"
			keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<CR>", opts) -- show lsp definitions

			opts.desc = "LSP: Show implementations"
			keymap.set("n", "gi", "<cmd>Telescope lsp_implementations<CR>", opts) -- show lsp implementations

			opts.desc = "LSP: Show type definitions"
			keymap.set("n", "gt", "<cmd>Telescope lsp_type_definitions<CR>", opts) -- show lsp type definitions

			opts.desc = "LSP: See available code actions"
			keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts) -- see available code actions, in visual mode will apply to selection

			opts.desc = "LSP: Smart rename"
			keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts) -- smart rename

			opts.desc = "LSP: Show buffer diagnostics"
			keymap.set("n", "<leader>D", "<cmd>Telescope diagnostics bufnr=0<CR>", opts) -- show  diagnostics for file

			opts.desc = "LSP: Show line diagnostics"
			keymap.set("n", "<leader>e", vim.diagnostic.open_float, opts) -- show diagnostics for line

			--- [[ Available as defaults since Neovim 0.11.x ]]
			-- opts.desc = "LSP: Go to previous diagnostic"
			-- keymap.set("n", "[d", vim.diagnostic.jump({ count = 1 }), opts) -- jump to previous diagnostic in buffer
			--
			-- opts.desc = "LSP: Go to next diagnostic"
			-- keymap.set("n", "]d", vim.diagnostic.jump({ count = -1 }), opts) -- jump to next diagnostic in buffer
			--- ]]

			opts.desc = "LSP: Show documentation for what is under cursor"
			keymap.set("n", "K", vim.lsp.buf.hover, opts) -- show documentation for what is under cursor

			opts.desc = "Restart LSP"
			keymap.set("n", "<leader>rs", ":LspRestart<CR>", opts) -- mapping to restart lsp if necessary

			opts.desc = "LSP Format buffer"
			keymap.set("n", "<leader>F", function()
				vim.lsp.buf.format({ async = true })
			end, opts)

			opts.desc = "LSP Signature help"
			keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, opts)
		end

		-- used to enable autocompletion (assign to every lsp server config)
		local capabilities = require("blink.cmp").get_lsp_capabilities({
			textDocument = { completion = { completionItem = { snippetSupport = false } } },
		})

		-- configure lua server (with special settings)
		lspconfig.lua_ls.setup({
			capabilities = capabilities,
			on_attach = on_attach,
			settings = {
				Lua = {
					-- make the language server recognize "vim" global
					diagnostics = {
						globals = { "vim" },
					},
					telemetry = { enable = false },
					workspace = {
						checkThirdParty = false,
						-- make language server aware of runtime files
						library = {
							[vim.fn.expand("$VIMRUNTIME/lua")] = true,
							[vim.fn.stdpath("config") .. "/lua"] = true,
						},
					},
					codeLens = {
						enable = true,
					},
					completion = {
						callSnippet = "Replace",
					},
					doc = {
						privateName = { "^_" },
					},
					hint = {
						enable = true,
						setType = false,
						paramType = true,
						paramName = "Disable",
						semicolon = "Disable",
						arrayIndex = "Disable",
					},
				},
			},
		})

		-- asm/nasm
		lspconfig.asm_lsp.setup({
			capabilities = capabilities,
			on_attach = on_attach,
		})

		-- bash / shell
		lspconfig.bashls.setup({
			filetypes = { "sh", "zsh" },
			capabilities = capabilities,
			on_attach = on_attach,
		})

		-- c/c++
		lspconfig.clangd.setup({
			capabilities = capabilities,
			on_attach = on_attach,
			cmd = {
				"clangd",
				"--all-scopes-completion",
				"--background-index", -- should include a compile_commands.json or .txt
				"--clang-tidy",
				"--cross-file-rename",
				"--completion-style=detailed",
				"--fallback-style=Microsoft",
				"--function-arg-placeholders",
				"--header-insertion-decorators",
				"--header-insertion=never",
				"--limit-results=10",
				"--pch-storage=memory",
				"--query-driver=/usr/include/*",
				"--suggest-missing-includes",
			},
		})

		-- css
		lspconfig.cssls.setup({
			capabilities = capabilities,
			on_attach = on_attach,
		})

		-- esbonio (sphinx)
		lspconfig.esbonio.setup({
			capabilities = capabilities,
			on_attach = on_attach,
		})

		-- go lang
		-- lspconfig.gopls.setup({
		-- 	capabilities = capabilities,
		-- 	on_attach = on_attach,
		-- })

		-- html
		lspconfig.html.setup({
			capabilities = capabilities,
			on_attach = on_attach,
		})

		-- json
		lspconfig.jsonls.setup({
			capabilities = capabilities,
			on_attach = on_attach,
		})

		lspconfig.marksman.setup({
			capabilities = capabilities,
			on_attach = on_attach,
		})

		-- python
		lspconfig.pyright.setup({
			capabilities = capabilities,
			on_attach = on_attach,
		})

		-- rust (called from rustaceanvim)
		lspconfig.rust_analyzer.setup({
			capabilities = capabilities,
			on_attach = on_attach,
		})

		-- typescript
		lspconfig.ts_ls.setup({
			capabilities = capabilities,
			on_attach = on_attach,
		})

		-- vim
		lspconfig.vimls.setup({
			capabilities = capabilities,
			on_attach = on_attach,
		})

		-- xml
		lspconfig.lemminx.setup({
			capabilities = capabilities,
			on_attach = on_attach,
		})

		-- yaml
		lspconfig.yamlls.setup({
			capabilities = capabilities,
			on_attach = on_attach,
		})

		-- hyprls
		lspconfig.hyprls.setup({
			capabilities = capabilities,
			on_attach = on_attach,
		})

		-- c3 lsp
		local lsp_configurations = require("lspconfig.configs")

		if not lsp_configurations.c3_lsp then
			lsp_configurations.c3_lsp = {
				default_config = {
					name = "c3_lsp",
					cmd = {
						"/usr/local/bin/c3lsp",
					},
					filetypes = { "c3" },
					root_dir = require("lspconfig.util").root_pattern(".git", "CMakeLists.txt"),
				},
			}
		end

		lspconfig.c3_lsp.setup({
			capabilities = capabilities,
			on_attach = on_attach,
		})

		lspconfig.zls.setup({
			capabilities = capabilities,
			on_attach = on_attach,
		})

		-- Change border of documentation hover window, See https://github.com/neovim/neovim/pull/13998.
		vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
			border = "rounded",
		})

		vim.diagnostic.config({
			underline = true,
			update_in_insert = false,
			virtual_text = {
				spacing = 4,
				source = "if_many",
				prefix = vim.fn.has("nvim-0.10.0") == 0 and "●" or function(diagnostic)
					local icons = Util.config.icons.diagnostics
					for d, icon in pairs(icons) do
						if diagnostic.severity == vim.diagnostic.severity[d:upper()] then
							return icon
						end
					end
				end,
			},
			severity_sort = true,
			signs = {
				text = {
					[vim.diagnostic.severity.ERROR] = Util.config.icons.diagnostics.Error,
					[vim.diagnostic.severity.WARN] = Util.config.icons.diagnostics.Warn,
					[vim.diagnostic.severity.HINT] = Util.config.icons.diagnostics.Hint,
					[vim.diagnostic.severity.INFO] = Util.config.icons.diagnostics.Info,
				},
			},
		})
	end,
}
