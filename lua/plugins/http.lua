return {
  {
    "mistweaverco/kulala.nvim",
    ft = "http",
    cmd = "Rest",
    keys = {
      { "<leader>rr", function() require("kulala").run() end,          desc = "Run request" },
      { "<leader>ra", function() require("kulala").run_all() end,      desc = "Run all requests" },
      { "<leader>rl", function() require("kulala").replay() end,       desc = "Replay last request" },
      { "<leader>ri", function() require("kulala").inspect() end,      desc = "Inspect request" },
      { "<leader>re", function() require("kulala").set_selected_env() end, desc = "Set environment" },
      { "<leader>rc", function() require("kulala").copy() end,         desc = "Copy as cURL" },
    },
    opts = {
      default_headers = {
        ["Content-Type"] = "application/json",
      },
      vscode_rest_client_environmentvars = true,
    },
  },
}
