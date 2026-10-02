return {
  "lewis6991/gitsigns.nvim",
  event = "LazyFile",
  opts = {
    signs = {
      add = { text = "▎" },
      change = { text = "▎" },
      delete = { text = "▔" },
      topdelete = { text = "▔" },
      changedelete = { text = "▎" },
      untracked = { text = "▎" },
    },
    signs_staged = {
      add = { text = "▎" },
      change = { text = "▎" },
      delete = { text = "▔" },
      topdelete = { text = "▔" },
      changedelete = { text = "▎" },
    },
    signs_staged_enable = true,
    signcolumn = true,
    numhl = true,
    linehl = false,
    word_diff = true,
    watch_gitdir = {
      follow_files = true,
    },
    auto_attach = true,
    attach_to_untracked = false,
    preview_config = {
      border = "rounded",
      style = "minimal",
      relative = "cursor",
      row = 0,
      col = 1,
    },
    on_attach = function(bufnr)
      local gs = require("gitsigns")

      local function map(mode, l, r, opts)
        opts = opts or {}
        opts.buffer = bufnr
        vim.keymap.set(mode, l, r, opts)
      end

      -- Navigation
      map("n", "<leader>g<Down>", function()
        if vim.wo.diff then
          vim.cmd.normal({ "<leader>g<Down>", bang = true })
        else
          gs.nav_hunk("next")
        end
      end, { desc = "Git: Next hunk" })

      map("n", "<leader>g<Up>", function()
        if vim.wo.diff then
          vim.cmd.normal({ "<leader>g<Up>", bang = true })
        else
          gs.nav_hunk("prev")
        end
      end, { desc = "Git: Previous hunk" })

      -- Actions
      map("n", "<leader>gp", gs.preview_hunk, { desc = "Git: Preview hunk" })
      map("n", "<leader>gi", gs.preview_hunk_inline, { desc = "Git: Preview hunk inline" })
      map("n", "<leader>gd", gs.diffthis, { desc = "Git: Diff this" })
      map("n", "<leader>gD", function()
        gs.diffthis("~")
      end, { desc = "Git: Diff this (against HEAD~)" })
      map("v", "<leader>hs", function()
        gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
      end, { desc = "Git: Stage hunk" })
      map("n", "<leader>gU", gs.undo_stage_hunk, { desc = "Git: Undo stage hunk" })
      map("n", "<leader>gS", gs.stage_buffer, { desc = "Git: Stage buffer" })
      map("n", "<leader>gR", gs.reset_buffer, { desc = "Git: Reset buffer" })
      map("n", "<leader>gu", function()
        gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
      end, { desc = "Git: Reset hunk" })
      map("n", "<leader>bl", function()
        gs.blame_line({ full = true })
      end, { desc = "Git: Blame line" })
      map("n", "<leader>tb", gs.toggle_current_line_blame, { desc = "Git: Toggle current line blame" })
      map("n", "<leader>td", gs.toggle_deleted, { desc = "Git: Toggle deleted" })
      map("n", "<leader>gq", function()
        gs.setqflist("all")
      end, { desc = "Git: Quickfix all hunks (repo)" })

      -- Text object
      map({ "o", "x" }, "ih", gs.select_hunk, { desc = "Git: Select hunk" })
    end,
  },
  config = function(_, opts)
    require("gitsigns").setup(opts)

    -- Snacks toggle for gitsigns sign column
    Snacks.toggle({
      name = "Git Signs",
      get = function()
        return require("gitsigns.config").config.signcolumn
      end,
      set = function(state)
        require("gitsigns").toggle_signs(state)
      end,
    }):map("<leader>uG")
  end,
}
