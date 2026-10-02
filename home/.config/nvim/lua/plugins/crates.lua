return {
  "saecki/crates.nvim",
  event = { "BufRead Cargo.toml" },
  opts = {
    completion = {
      -- blink.cmp is used instead of nvim-cmp; cmp integration intentionally omitted
      crates = {
        enabled = true,
      },
    },
    lsp = {
      enabled = true,
      on_attach = function(client, bufnr)
        local opts = { buffer = bufnr, silent = true }
        vim.keymap.set("n", "K", function()
          if require("crates").popup_available() then
            require("crates").show_popup()
          else
            vim.lsp.buf.hover()
          end
        end, vim.tbl_extend("force", opts, { desc = "Show crate documentation" }))
      end,
      actions = true,
      completion = true,
      hover = true,
    },
    -- none-ls is a drop-in replacement for null-ls; require("null-ls") resolves correctly
    null_ls = {
      enabled = true,
      name = "crates.nvim",
    },
    popup = {
      autofocus = true,
      hide_on_select = true,
      border = "rounded",
    },
  },
}
