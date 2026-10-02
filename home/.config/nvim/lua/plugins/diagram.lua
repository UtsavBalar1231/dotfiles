return {
  "3rd/diagram.nvim",
  -- NOTE: diagram.nvim officially requires 3rd/image.nvim, but we've disabled
  -- it in favour of snacks.image. diagram.nvim may not render correctly until
  -- it gains snacks.image support.
  dependencies = {},
  opts = {
    events = {
      render_buffer = { "InsertLeave", "BufWinEnter", "TextChanged" },
      clear_buffer = { "BufLeave" },
    },
    renderer_options = {
      mermaid = {
        background = nil, -- nil | "transparent" | "white" | "#hex"
        theme = "forest", -- nil | "default" | "dark" | "forest" | "neutral"
        scale = 1, -- nil | 1 (default) | 2 | 3 | ...
        width = nil, -- nil | 800 | 400 | ...
        height = nil, -- nil | 600 | 300 | ...
        cli_args = nil, -- nil | { "--no-sandbox" } | { "-p", "/path/to/puppeteer" } | ...
      },
      plantuml = {
        charset = "utf-8",
        cli_args = nil, -- nil | { "-Djava.awt.headless=true" } | ...
      },
      d2 = {
        theme_id = 1,
        dark_theme_id = nil,
        scale = nil,
        layout = nil,
        sketch = nil,
        cli_args = nil, -- nil | { "--pad", "0" } | ...
      },
      gnuplot = {
        size = "800,600", -- nil | "800,600" | ...
        font = nil, -- nil | "Arial,12" | ...
        theme = "dark", -- nil | "light" | "dark" | custom theme string
        cli_args = nil, -- nil | { "-p" } | { "-c", "config.plt" } | ...
      },
    },
  },
  keys = {
    {
      "K",
      function()
        require("diagram").show_diagram_hover()
      end,
      mode = "n",
      ft = { "markdown", "norg" },
      desc = "Show diagram in new tab",
    },
  },
}
