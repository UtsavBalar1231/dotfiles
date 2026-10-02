return {
  "stevearc/conform.nvim",
  opts = {
    formatters = {
      prettier = {
        prepend_args = { "--use-tabs", "--tab-width", "4" },
      },
    },
  },
}
