return {
  -- Override blink.cmp configuration
  {
    "saghen/blink.cmp",
    dependencies = {
      "L3MON4D3/LuaSnip",
      "xzbdmw/colorful-menu.nvim",
    },
    opts = {
      snippets = {
        preset = "luasnip",
      },

      signature = {
        enabled = true,
      },

      sources = {
        per_filetype = {
          codecompanion = { "codecompanion" },
        },
        providers = {
          cmdline = {
            -- Ignore cmdline completions when executing shell commands
            enabled = function()
              return vim.fn.getcmdtype() ~= ":" or not vim.fn.getcmdline():match("^[%%0-9,'<>%-]*!")
            end,
          },
          buffer = {
            max_items = 3,
            min_keyword_length = 3,
            score_offset = 100,
          },
          lsp = {
            min_keyword_length = 2,
            score_offset = 80,
          },
          path = {
            score_offset = 25,
            fallbacks = { "snippets", "buffer" },
            -- Path sources triggered by "/" interfere with CopilotChat commands
            enabled = function()
              return vim.bo.filetype ~= "copilot-chat"
            end,
            opts = {
              get_cwd = function(context)
                return vim.fn.expand(("#%d:p:h"):format(context.bufnr))
              end,
              trailing_slash = false,
              show_hidden_files_by_default = true,
              label_trailing_slash = true,
            },
          },
        },
      },

      completion = {
        documentation = {
          auto_show = false,
          auto_show_delay_ms = 150,
        },
        menu = {
          draw = {
            components = {
              label = {
                text = function(ctx)
                  return require("colorful-menu").blink_components_text(ctx)
                end,
                highlight = function(ctx)
                  return require("colorful-menu").blink_components_highlight(ctx)
                end,
              },
            },
          },
        },
      },
    },
  },
}
