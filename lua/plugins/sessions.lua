return {
  {
    "folke/persistence.nvim",
    event = "VeryLazy",
    opts = {},
    keys = {
      { "<leader>vrs", function() require("persistence").load() end,                desc = "Restore session" },
      { "<leader>vrl", function() require("persistence").load({ last = true }) end, desc = "Restore last session" },
      { "<leader>vrd", function() require("persistence").stop() end,                desc = "Don't save session" },
    },
  },
}
