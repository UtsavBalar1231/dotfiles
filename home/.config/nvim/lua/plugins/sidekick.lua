-- NOTE: <leader>a keymaps below may conflict with treesitter-textobjects swap (<leader>a).
return {
  "folke/sidekick.nvim",
  enabled = false,
  event = "LazyFile",
  opts = {
    cli = {
      mux = {
        backend = "zellij",
        enabled = true,
      },
      win = {
        layout = "right",
        split = {
          width = 100,
          height = 30,
        },
      },
    },
  },
  keys = {
    {
      "<Tab>",
      function()
        if not require("sidekick").nes_jump_or_apply() then
          return "<Tab>" -- fallback to normal tab
        end
      end,
      expr = true,
      desc = "Sidekick: Goto/Apply Next Edit Suggestion",
      mode = { "n" },
    },
    {
      "<c-.>",
      function()
        require("sidekick.cli").toggle()
      end,
      desc = "Sidekick: Toggle CLI",
      mode = { "n", "t", "i", "x" },
    },
    {
      "<leader>aa",
      function()
        require("sidekick.cli").toggle()
      end,
      desc = "Sidekick: Toggle CLI",
    },
    {
      "<leader>as",
      function()
        require("sidekick.cli").select()
      end,
      desc = "Sidekick: Select CLI",
    },
    {
      "<leader>ad",
      function()
        require("sidekick.cli").close()
      end,
      desc = "Sidekick: Detach CLI Session",
    },
    {
      "<leader>ac",
      function()
        require("sidekick.cli").toggle({ name = "claude", focus = true })
      end,
      desc = "Sidekick: Toggle Claude",
      mode = { "n", "v" },
    },
    {
      "<leader>ag",
      function()
        require("sidekick.cli").toggle({ name = "gemini", focus = true })
      end,
      desc = "Sidekick: Toggle Gemini",
      mode = { "n", "v" },
    },
    {
      "<leader>ap",
      function()
        require("sidekick.cli").prompt()
      end,
      desc = "Sidekick: Select Prompt",
      mode = { "n", "x" },
    },
    {
      "<leader>at",
      function()
        require("sidekick.cli").send({ msg = "{this}" })
      end,
      mode = { "x", "n" },
      desc = "Sidekick: Send This",
    },
    {
      "<leader>af",
      function()
        require("sidekick.cli").send({ msg = "{file}" })
      end,
      desc = "Sidekick: Send File",
    },
    {
      "<leader>av",
      function()
        require("sidekick.cli").send({ msg = "{selection}" })
      end,
      mode = { "x" },
      desc = "Sidekick: Send Visual Selection",
    },
    {
      "<leader>an",
      function()
        require("sidekick.nes").update()
      end,
      desc = "Sidekick: Request Next Edit",
      mode = { "n" },
    },
    {
      "<leader>aA",
      function()
        require("sidekick.nes").apply()
      end,
      desc = "Sidekick: Apply Next Edit",
      mode = { "n" },
    },
    {
      "<leader>ax",
      function()
        require("sidekick.nes").clear()
      end,
      desc = "Sidekick: Clear Suggestions",
      mode = { "n" },
    },
  },
}
