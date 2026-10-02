return {
  "mrcjkb/rustaceanvim",
  ft = { "rust" },
  version = "^8",
  lazy = false,
  init = function()
    vim.g.rustaceanvim = {
      tools = {
        code_actions = {
          ui_select_fallback = false,
        },
        float_win_config = {
          auto_focus = false,
        },
        reload_workspace_from_cargo_toml = true,
        open_url = vim.ui.open,
      },
      server = {
        standalone = true,
        on_attach = function(client, bufnr)
          vim.bo[bufnr].omnifunc = "v:lua.vim.lsp.omnifunc"

          local opts = { noremap = true, silent = true, buffer = bufnr }

          vim.keymap.set("n", "<leader>ca", function()
            vim.cmd.RustLsp("codeAction")
          end, vim.tbl_extend("force", opts, { desc = "Rust: Code Action" }))

          vim.keymap.set("n", "K", function()
            vim.cmd.RustLsp({ "hover", "actions" })
          end, vim.tbl_extend("force", opts, { desc = "Rust: Hover Actions" }))

          vim.keymap.set("n", "<leader>rr", function()
            vim.cmd.RustLsp("runnables")
          end, vim.tbl_extend("force", opts, { desc = "Rust: Runnables" }))

          vim.keymap.set("n", "<leader>rt", function()
            vim.cmd.RustLsp("testables")
          end, vim.tbl_extend("force", opts, { desc = "Rust: Testables" }))

          vim.keymap.set("n", "<leader>rm", function()
            vim.cmd.RustLsp("expandMacro")
          end, vim.tbl_extend("force", opts, { desc = "Rust: Expand Macro" }))

          vim.keymap.set("n", "<leader>rc", function()
            vim.cmd.RustLsp("openCargo")
          end, vim.tbl_extend("force", opts, { desc = "Rust: Open Cargo.toml" }))

          vim.keymap.set("n", "<leader>rp", function()
            vim.cmd.RustLsp("parentModule")
          end, vim.tbl_extend("force", opts, { desc = "Rust: Parent Module" }))

          vim.keymap.set("n", "J", function()
            vim.cmd.RustLsp("joinLines")
          end, vim.tbl_extend("force", opts, { desc = "Rust: Join Lines" }))

          vim.keymap.set("n", "<leader>rs", function()
            vim.cmd.RustLsp("ssr")
          end, vim.tbl_extend("force", opts, { desc = "Rust: Structural Search Replace" }))

          vim.keymap.set("n", "<leader>rT", function()
            vim.cmd.RustLsp("syntaxTree")
          end, vim.tbl_extend("force", opts, { desc = "Rust: Syntax Tree" }))

          vim.keymap.set("n", "<leader>rh", function()
            vim.cmd.RustLsp({ "view", "hir" })
          end, vim.tbl_extend("force", opts, { desc = "Rust: View HIR" }))

          vim.keymap.set("n", "<leader>rM", function()
            vim.cmd.RustLsp({ "view", "mir" })
          end, vim.tbl_extend("force", opts, { desc = "Rust: View MIR" }))

          vim.keymap.set("n", "<leader>re", function()
            vim.cmd.RustLsp("explainError")
          end, vim.tbl_extend("force", opts, { desc = "Rust: Explain Error" }))

          vim.keymap.set("n", "<leader>rD", function()
            vim.cmd.RustLsp("renderDiagnostic")
          end, vim.tbl_extend("force", opts, { desc = "Rust: Render Diagnostic" }))

          vim.keymap.set("n", "<leader>rmu", function()
            vim.cmd.RustLsp("moveItem", "up")
          end, vim.tbl_extend("force", opts, { desc = "Rust: Move Item Up" }))
          vim.keymap.set("n", "<leader>rmd", function()
            vim.cmd.RustLsp("moveItem", "down")
          end, vim.tbl_extend("force", opts, { desc = "Rust: Move Item Down" }))

          vim.keymap.set("n", "<leader>rwr", function()
            vim.cmd.RustLsp({ "workspaceSymbol", "allSymbols" })
          end, vim.tbl_extend("force", opts, { desc = "Rust: Workspace Symbols" }))

          vim.keymap.set("n", "<leader>rwR", function()
            vim.cmd.RustLsp("reloadWorkspace")
          end, vim.tbl_extend("force", opts, { desc = "Rust: Reload Workspace" }))

          -- Disabled by default to prevent errors
          if client.server_capabilities.inlayHintProvider then
            vim.keymap.set("n", "<leader>ih", function()
              local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr })
              local ok, err = pcall(vim.lsp.inlay_hint.enable, not enabled, { bufnr = bufnr })
              if ok then
                vim.notify(string.format("Inlay hints %s", enabled and "disabled" or "enabled"), vim.log.levels.INFO)
              else
                vim.notify(
                  string.format("Failed to toggle inlay hints: %s", err or "Unknown error"),
                  vim.log.levels.WARN
                )
              end
            end, {
              buffer = bufnr,
              noremap = true,
              silent = true,
              desc = "Toggle inlay hints (manual only)",
            })
          end

          -- Register rust-analyzer with LazyVim.format system
          if client.supports_method("textDocument/formatting") then
            LazyVim.format.register({
              name = "rust-analyzer",
              primary = true,
              priority = 150, -- Higher than conform (100) and LSP (1)
              format = function(buf)
                vim.lsp.buf.format({
                  bufnr = buf,
                  name = "rust-analyzer",
                  async = false,
                })
              end,
              sources = function(buf)
                return { "rust-analyzer" }
              end,
            })
          end
        end,
        default_settings = {
          ["rust-analyzer"] = {
            imports = {
              granularity = {
                group = "module",
              },
              merge = {
                glob = true,
              },
              prefix = "self",
            },
            cargo = {
              allFeatures = true,
              loadOutDirsFromCheck = true,
              runBuildScripts = true,
              buildScripts = {
                enable = true,
              },
            },
            checkOnSave = {
              enable = true,
              command = "clippy",
              allFeatures = true,
              extraArgs = {
                "--",
                "--no-deps",
                "-W",
                "clippy::pedantic",
                "-W",
                "clippy::nursery",
              },
            },
            diagnostics = {
              enable = true,
              experimental = {
                enable = true,
              },
              styleLints = {
                enable = true,
              },
            },
            procMacro = {
              enable = true,
              attributes = {
                enable = true,
              },
              ignored = {
                ["async-trait"] = { "async_trait" },
                ["napi-derive"] = { "napi" },
                ["async-recursion"] = { "async_recursion" },
              },
            },
            rustfmt = {
              enableRangeFormatting = true,
              extraArgs = { "+nightly" },
            },
            lens = {
              enable = true,
              debug = {
                enable = true,
              },
              implementations = {
                enable = true,
              },
              references = {
                adt = {
                  enable = true,
                },
                enumVariant = {
                  enable = true,
                },
                method = {
                  enable = true,
                },
                trait = {
                  enable = true,
                },
              },
              run = {
                enable = true,
              },
            },
            inlayHints = {
              bindingModeHints = {
                enable = true,
              },
              chainingHints = {
                enable = true,
              },
              closingBraceHints = {
                enable = true,
                minLines = 25,
              },
              closureReturnTypeHints = {
                enable = "always",
              },
              discriminantHints = {
                enable = "always",
              },
              lifetimeElisionHints = {
                enable = "skip_trivial",
                useParameterNames = true,
              },
              maxLength = 120,
              parameterHints = {
                enable = true,
              },
              rangeExclusiveHints = {
                enable = true,
              },
              reborrowHints = {
                enable = "always",
              },
              renderColons = true,
              typeHints = {
                enable = true,
                hideClosureInitialization = false,
                hideNamedConstructor = false,
              },
            },
            completion = {
              addCallParenthesis = true,
              addCallArgumentSnippets = true,
              postfix = {
                enable = true,
              },
              autoimport = {
                enable = true,
              },
              autoself = {
                enable = true,
              },
              snippets = {
                custom = {
                  ["Arc::new"] = {
                    postfix = "arc",
                    body = "Arc::new(${receiver})",
                    requires = "std::sync::Arc",
                    description = "Wrap in Arc",
                    scope = "expr",
                  },
                  ["Box::new"] = {
                    postfix = "box",
                    body = "Box::new(${receiver})",
                    description = "Wrap in Box",
                    scope = "expr",
                  },
                  ["Some"] = {
                    postfix = "some",
                    body = "Some(${receiver})",
                    description = "Wrap in Some",
                    scope = "expr",
                  },
                  ["Ok"] = {
                    postfix = "ok",
                    body = "Ok(${receiver})",
                    description = "Wrap in Ok",
                    scope = "expr",
                  },
                  ["Err"] = {
                    postfix = "err",
                    body = "Err(${receiver})",
                    description = "Wrap in Err",
                    scope = "expr",
                  },
                },
              },
            },
            semanticHighlighting = {
              strings = {
                enable = true,
              },
              punctuation = {
                enable = true,
                separate = {
                  macro = {
                    bang = true,
                  },
                },
                specialization = {
                  enable = true,
                },
              },
              operator = {
                enable = true,
                specialization = {
                  enable = true,
                },
              },
            },
            workspace = {
              symbol = {
                search = {
                  kind = "all_symbols",
                  limit = 256,
                  scope = "workspace",
                },
              },
            },
            files = {
              excludeDirs = {
                ".direnv",
                ".git",
                ".github",
                ".gitlab",
                "bin",
                "node_modules",
                "target",
                "venv",
                ".venv",
              },
              watcher = "client",
            },
            highlightRelated = {
              breakPoints = {
                enable = true,
              },
              closureCaptures = {
                enable = true,
              },
              exitPoints = {
                enable = true,
              },
              references = {
                enable = true,
              },
              yieldPoints = {
                enable = true,
              },
            },
            hover = {
              actions = {
                debug = {
                  enable = true,
                },
                enable = true,
                gotoTypeDef = {
                  enable = true,
                },
                implementations = {
                  enable = true,
                },
                references = {
                  enable = true,
                },
                run = {
                  enable = true,
                },
              },
              documentation = {
                enable = true,
                keywords = {
                  enable = true,
                },
              },
              links = {
                enable = true,
              },
              memoryLayout = {
                alignment = "hexadecimal",
                enable = true,
                niches = true,
                offset = "hexadecimal",
                size = "both",
              },
            },
            assist = {
              emitMustUse = true,
              expressionFillDefault = "todo",
              importEnforceGranularity = true,
              importGroup = true,
              importPrefix = "self",
            },
            cache = {
              warmup = true,
            },
          },
        },
      },
    }
  end,
  config = function()
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "rust",
      callback = function()
        vim.bo.makeprg = "cargo build"
        -- Auto-formatting on save disabled
        -- Manually format with <leader>F keymap
        -- vim.api.nvim_create_autocmd("BufWritePre", {
        -- 	buffer = 0,
        -- 	callback = function()
        -- 		vim.lsp.buf.format({ async = false })
        -- 	end,
        -- })
      end,
    })
  end,
}
