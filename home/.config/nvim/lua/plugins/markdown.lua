return {
  -- Disable markdownlint-cli2 linter (too noisy)
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = {
      linters_by_ft = {
        markdown = {},
      },
    },
  },

  -- Remove markdownlint-cli2 from conform formatters, keep prettier + toc
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        ["markdown"] = { "prettier", "markdown-toc" },
        ["markdown.mdx"] = { "prettier", "markdown-toc" },
      },
    },
  },
}
