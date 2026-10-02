return {
  "akinsho/bufferline.nvim",
  version = "*",
  dependencies = "nvim-tree/nvim-web-devicons",
  event = "VeryLazy",
  keys = {
    { "<leader><tab>l", "<cmd>BufferLineCycleNext<cr>", desc = "Next Buffer" },
    { "<leader><tab>h", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev Buffer" },
    { "<leader><tab>L", "<cmd>BufferLineMoveNext<cr>", desc = "Move Buffer Next" },
    { "<leader><tab>H", "<cmd>BufferLineMovePrev<cr>", desc = "Move Buffer Prev" },
    { "<leader><tab>p", "<cmd>BufferLineTogglePin<cr>", desc = "Toggle Pin" },
    { "<leader><tab>P", "<cmd>BufferLineGroupClose ungrouped<cr>", desc = "Delete Non-Pinned Buffers" },
    { "<leader><tab>o", "<cmd>BufferLineCloseOthers<cr>", desc = "Delete Other Buffers" },
    { "<leader><tab>r", "<cmd>BufferLineCloseRight<cr>", desc = "Delete Buffers to the Right" },
    { "<leader><tab>[", "<cmd>BufferLineCloseLeft<cr>", desc = "Delete Buffers to the Left" },
    { "<leader><tab>1", "<cmd>BufferLineGoToBuffer 1<cr>", desc = "Go to Buffer 1" },
    { "<leader><tab>2", "<cmd>BufferLineGoToBuffer 2<cr>", desc = "Go to Buffer 2" },
    { "<leader><tab>3", "<cmd>BufferLineGoToBuffer 3<cr>", desc = "Go to Buffer 3" },
    { "<leader><tab>4", "<cmd>BufferLineGoToBuffer 4<cr>", desc = "Go to Buffer 4" },
    { "<leader><tab>5", "<cmd>BufferLineGoToBuffer 5<cr>", desc = "Go to Buffer 5" },
    { "<leader><tab>6", "<cmd>BufferLineGoToBuffer 6<cr>", desc = "Go to Buffer 6" },
    { "<leader><tab>7", "<cmd>BufferLineGoToBuffer 7<cr>", desc = "Go to Buffer 7" },
    { "<leader><tab>8", "<cmd>BufferLineGoToBuffer 8<cr>", desc = "Go to Buffer 8" },
    { "<leader><tab>9", "<cmd>BufferLineGoToBuffer 9<cr>", desc = "Go to Buffer 9" },
    { "<leader><tab>$", "<cmd>BufferLineGoToBuffer -1<cr>", desc = "Go to Last Buffer" },
  },
  opts = {
    options = {
      mode = "buffers",
      themable = true,
      numbers = "none",
      close_command = function(n)
        require("snacks").bufdelete(n)
      end,
      right_mouse_command = function(n)
        require("snacks").bufdelete(n)
      end,
      left_mouse_command = "buffer %d",
      middle_mouse_command = nil,
      indicator = {
        icon = "▎",
        style = "icon",
      },
      buffer_close_icon = "󰅙",
      modified_icon = "",
      close_icon = "󰅙",
      left_trunc_marker = "",
      right_trunc_marker = "",
      max_name_length = 30,
      max_prefix_length = 30,
      truncate_names = true,
      tab_size = 21,
      diagnostics = "nvim_lsp",
      diagnostics_update_in_insert = false,
      diagnostics_update_on_event = true,
      diagnostics_indicator = function(count, level, diagnostics_dict, context)
        local icon = level:match("error") and " " or " "
        return " " .. icon .. count
      end,
      offsets = {
        {
          filetype = "NvimTree",
          text = "File Explorer",
          text_align = "center",
          separator = true,
        },
        {
          filetype = "neo-tree",
          text = "File Explorer",
          text_align = "center",
          separator = true,
        },
      },
      color_icons = true,
      show_buffer_icons = true,
      show_buffer_close_icons = true,
      show_close_icon = true,
      show_tab_indicators = true,
      show_duplicate_prefix = true,
      duplicates_across_groups = true,
      persist_buffer_sort = true,
      move_wraps_at_ends = false,
      separator_style = "thin",
      enforce_regular_tabs = false,
      always_show_bufferline = true,
      auto_toggle_bufferline = true,
      hover = {
        enabled = true,
        delay = 200,
        reveal = { "close" },
      },
      sort_by = "insert_after_current",
    },
  },
  config = function(_, opts)
    local bufferline = require("bufferline")
    opts.options.style_preset = {
      bufferline.style_preset.no_italic,
      bufferline.style_preset.no_bold,
    }
    bufferline.setup(opts)

    -- Fix bufferline when restoring a session
    vim.api.nvim_create_autocmd({ "BufAdd", "BufDelete" }, {
      callback = function()
        vim.schedule(function()
          pcall(require("bufferline").refresh)
        end)
      end,
    })
  end,
}
