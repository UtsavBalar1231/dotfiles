return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPost", "BufNewFile", "BufWritePre" },
	enabled = not vim.g.vscode,
	dependencies = {
		"saghen/blink.cmp",
	},
	opts = {
		features = {
			codelens = true,
			inlay_hints = false,
			semantic_tokens = true,
		},
		defaults = {
			hover = {
				border = Util.config.icons.border,
				silent = true,
			},
			signature_help = {
				border = Util.config.icons.border,
				silent = true,
				focusable = false,
			},
		},
	},
	config = function()
		local lspconfig = require("lspconfig")
		local capabilities = require("blink.cmp").get_lsp_capabilities({
			workspace = {
				fileOperations = {
					didRename = true,
					willRename = true,
				},
			},
			textDocument = {
				completion = {
					completionItem = { snippetSupport = true },
				},
			},
		})

		-- Configure diagnostics
		vim.diagnostic.config({
			underline = true,
			update_in_insert = false,
			float = {
				focused = false,
				style = "minimal",
				source = true,
				header = "",
				prefix = "",
			},
			virtual_text = {
				spacing = 4,
				source = "if_many",
				prefix = vim.fn.has("nvim-0.10.0") == 0 and "●" or function(diagnostic)
					local icons = Util.config.icons.diagnostics
					for severity, icon in pairs(icons) do
						if diagnostic.severity == vim.diagnostic.severity[severity:upper()] then
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

		-- Common on_attach function
		local function on_attach(_, bufnr)
			local keymap = vim.keymap
			local opts = { noremap = true, silent = true, buffer = bufnr }

			-- Enable inlay hints if supported
			vim.lsp.inlay_hint.enable(true, { buffer = bufnr })

			-- Keybindings
			local mappings = {
				{
					mode = "n",
					lhs = "gD",
					rhs = vim.lsp.buf.declaration,
					desc = "LSP: Go to declaration",
				},
				{
					mode = { "n", "v" },
					lhs = "<leader>ca",
					rhs = vim.lsp.buf.code_action,
					desc = "LSP: See available code actions",
				},
				{
					mode = "n",
					lhs = "<leader>rn",
					rhs = vim.lsp.buf.rename,
					desc = "LSP: Smart rename",
				},
				{
					mode = "n",
					lhs = "<leader>e",
					rhs = vim.diagnostic.open_float,
					desc = "LSP: Show line diagnostics",
				},
				{
					mode = "n",
					lhs = "K",
					rhs = vim.lsp.buf.hover,
					desc = "LSP: Show documentation for what is under cursor",
				},
				{ mode = "n", lhs = "<leader>rs", rhs = ":LspRestart<CR>", desc = "Restart LSP" },
				{
					mode = "n",
					lhs = "<leader>F",
					rhs = function()
						vim.lsp.buf.format({ async = true })
					end,
					desc = "LSP Format buffer",
				},
				{ mode = "n", lhs = "<C-k>", rhs = vim.lsp.buf.signature_help, desc = "LSP Signature help" },
				{ mode = "n", lhs = "gra", rhs = vim.lsp.buf.code_action, desc = "LSP: Code action" },
				{ mode = "n", lhs = "grr", rhs = vim.lsp.buf.references, desc = "LSP: Find references" },
				{
					mode = "n",
					lhs = "gri",
					rhs = vim.lsp.buf.implementation,
					desc = "LSP: Go to implementation",
				},
				{ mode = "n", lhs = "grn", rhs = vim.lsp.buf.rename, desc = "LSP: Rename" },
				{ mode = "n", lhs = "g0", rhs = vim.lsp.buf.document_symbol, desc = "LSP: Document symbols" },
			}

			for _, map in ipairs(mappings) do
				opts.desc = map.desc
				keymap.set(map.mode, map.lhs, map.rhs, opts)
			end
		end

		-- Language server configurations
		local servers = {
			asm_lsp = {},
			astro = {},
			bashls = { filetypes = { "sh", "zsh" } },
			c3_lsp = {},
			clangd = {
				cmd = {
					"clangd",
					"--all-scopes-completion",
					"--background-index",
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
			},
			cssls = {},
			esbonio = {},
			html = {},
			hyprls = {},
			jsonls = {},
			lemminx = {},
			lua_ls = {
				settings = {
					Lua = {
						diagnostics = { globals = { "vim" } },
						telemetry = { enable = false },
						workspace = {
							checkThirdParty = false,
							library = {
								[vim.fn.expand("$VIMRUNTIME/lua")] = true,
								[vim.fn.stdpath("config") .. "/lua"] = true,
							},
						},
						codeLens = { enable = true },
						completion = { callSnippet = "Replace" },
						doc = { privateName = { "^_" } },
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
			},
			marksman = {},
			mdx_analyzer = {},
			pyright = {
				settings = {
					python = {
						analysis = {
							typeCheckingMode = "basic",
							autoSearchPaths = true,
							useLibraryCodeForTypes = true,
						},
					},
				},
			},
			qmlls = {
				cmd = {
					"qmlls6",
				},
			},
			rust_analyzer = {},
			texlab = {
				settings = {
					latex = {
						build = {
							args = { "-pdf", "-interaction=nonstopmode", "-synctex=1", "%f" },
							executable = "latexmk",
							forwardSearch = {
								executable = "zathura",
								args = { "--synctex-forward", "%l:1:%f", "%p" },
							},
							onSave = true,
						},
						chktex = { onEdit = true, onOpenAndSave = true },
						lint = { onChange = true, onEdit = true, onSave = true },
						latexindent = { enabled = true },
						forwardSearch = {
							executable = "zathura",
							args = { "--synctex-forward", "%l:1:%f", "%p" },
						},
					},
				},
			},

			ts_ls = {},
			vimls = {},
			yamlls = {
				settings = {
					yaml = {
						schemas = {
							["https://json.schemastore.org/github-workflow.json"] = "/.github/workflows/*",
							["https://json.schemastore.org/gitlab-ci.json"] = "/*gitlab-ci*.yaml",
							["https://raw.githubusercontent.com/kubernetes/kubernetes/master/api/openapi-spec/swagger.json"] = {
								"/*k8s*.yaml",
								"/*k8s*.yml",
								"/*kubernetes*.yaml",
								"/*kubernetes*.yml",
								"/*.k8s.yaml",
								"/*.k8s.yml",
							},
							["https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json"] = {
								"*docker-compose*.yml",
								"*docker-compose*.yaml",
							},
							["https://json.schemastore.org/helmfile.json"] = "*helmfile*.yaml",
							["https://json.schemastore.org/chart.json"] = "Chart.yaml",
							["https://json.schemastore.org/kustomization.json"] = "kustomization.yaml",
						},
						validate = true,
						completion = true,
						hover = true,
					},
				},
			},
			zls = {},
		}

		for server, config in pairs(servers) do
			config.capabilities = capabilities
			config.on_attach = on_attach
			lspconfig[server].setup(config)
		end

		-- Custom configuration for c3_lsp
		local lsp_configurations = require("lspconfig.configs")
		if not lsp_configurations.c3_lsp then
			lsp_configurations.c3_lsp = {
				default_config = {
					name = "c3_lsp",
					cmd = { "/usr/local/bin/c3lsp" },
					filetypes = { "c3" },
					root_dir = require("lspconfig.util").root_pattern(".git", "CMakeLists.txt"),
				},
			}
		end
	end,
}
