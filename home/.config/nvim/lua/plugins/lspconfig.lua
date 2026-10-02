return {
  "neovim/nvim-lspconfig",
  event = "LazyFile",
  enabled = not vim.g.vscode,
  dependencies = {
    "mason.nvim",
    { "mason-org/mason-lspconfig.nvim", config = function() end },
    "saghen/blink.cmp",
  },
  opts = {
    -- Diagnostics configuration
    diagnostics = {
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
        enabled = true,
        spacing = 4,
        prefix = function(diagnostic)
          local icons = LazyVim.config.icons.diagnostics
          for severity, icon in pairs(icons) do
            if diagnostic.severity == vim.diagnostic.severity[severity:upper()] then
              return icon
            end
          end
          return "●"
        end,
      },
      severity_sort = true,
      signs = {
        text = {
          [vim.diagnostic.severity.ERROR] = LazyVim.config.icons.diagnostics.Error,
          [vim.diagnostic.severity.WARN] = LazyVim.config.icons.diagnostics.Warn,
          [vim.diagnostic.severity.HINT] = LazyVim.config.icons.diagnostics.Hint,
          [vim.diagnostic.severity.INFO] = LazyVim.config.icons.diagnostics.Info,
        },
      },
    },

    -- Inlay hints
    inlay_hints = {
      enabled = true,
    },

    -- Servers configuration
    servers = {
      -- Default config for all servers
      ["*"] = {
        capabilities = {
          workspace = {
            fileOperations = {
              didRename = true,
              willRename = true,
            },
          },
        },
      },

      -- Individual server configurations
      asm_lsp = {},
      astro = {},

      bashls = {
        filetypes = { "sh", "zsh" },
      },

      c3_lsp = {},

      clangd = {
        cmd = {
          "clangd",
          "--all-scopes-completion",
          "--background-index",
          "--clang-tidy",
          "--completion-style=detailed",
          "--fallback-style=Microsoft",
          "--function-arg-placeholders",
          "--header-insertion-decorators",
          "--header-insertion=never",
          "--limit-results=10",
          "--pch-storage=memory",
          "--query-driver=/usr/include/*",
        },
      },

      copilot = {},
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
              diagnosticMode = "workspace",
              autoImportCompletions = true,
            },
          },
        },
      },

      qmlls = {
        cmd = { "qmlls6" },
      },

      -- NOTE: rust-analyzer is handled by rustaceanvim plugin
      -- Do not configure rust_analyzer here to avoid conflicts

      texlab = {
        settings = {
          texlab = {
            build = {
              args = { "-pdf", "-interaction=nonstopmode", "-synctex=1", "%f" },
              executable = "latexmk",
              onSave = true,
            },
            chktex = { onEdit = true, onOpenAndSave = true },
            latexindent = { modifyLineBreaks = false },
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
    },
  },
}
