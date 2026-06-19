return {
  {
    'folke/snacks.nvim',
    priority = 1000,
    lazy = false,
    module = 'snacks',
    opts = {
      bigfile = { enabled = true },
      explorer = { enabled = false },
      input = { enabled = true },
      notifier = { enabled = true, timeout = 3000 },
      picker = { enabled = false },
      quickfile = { enabled = true },
      scope = { enabled = true },
      scroll = { enabled = false },
      statuscolumn = { enabled = true },
      words = { enabled = true },
      terminal = {
        win = { style = 'terminal', position = 'bottom' },
      },
      lazygit = {
        enabled = true,
        configure = true,
        win = {
          style = 'lazygit',
          position = 'float',
          border = 'rounded',
          width = 0.9,
          height = 0.9,
        },
      },
    },
    keys = {
      {
        '<C-\\>',
        function()
          Snacks.terminal()
        end,
        desc = 'Toggle terminal',
        mode = { 'n', 't' },
      },
      {
        '<leader>gg',
        function()
          Snacks.lazygit()
        end,
        desc = 'Lazygit',
      },
      {
        '<leader>gf',
        function()
          Snacks.lazygit.log_file()
        end,
        desc = 'Lazygit file history',
      },
      {
        '<leader>gl',
        function()
          Snacks.lazygit.log()
        end,
        desc = 'Lazygit log',
      },
    },
  },
}
