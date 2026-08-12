return {
  {
    'echasnovski/mini.nvim',
    version = false,
    event = 'VeryLazy',
    dependencies = {
      { 'edisj/msgarea.nvim', optional = true },
    },
    config = function()
      require('mini.ai').setup {
        n_lines = 500,
        mappings = {
          around = 'a',
          inside = 'i',
          around_next = 'gan',
          around_last = 'gal',
          inside_next = 'gin',
          inside_last = 'gil',
        },
      }

      require('mini.surround').setup {
        n_lines = 100,
        highlight_duration = 500,
      }

      require('misc.pickers').setup()
    end,
  },

  {
    'mbbill/undotree',
    cmd = 'UndotreeToggle',
    keys = {
      { '<leader>vu', '<cmd>UndotreeToggle<cr>', desc = 'Undotree' },
    },
  },

  {
    'folke/flash.nvim',
    event = 'VeryLazy',
    opts = { modes = { search = { enabled = false } } },
    keys = {
      {
        's',
        mode = { 'n', 'x', 'o' },
        function()
          require('flash').jump()
        end,
        desc = 'Flash jump',
      },
    },
  },

  {
    'MagicDuck/grug-far.nvim',
    cmd = 'GrugFar',
    opts = { headerMaxWidth = 80 },
  },

  {
    'chrishrb/gx.nvim',
    lazy = true,
    keys = { { 'gx', '<cmd>Browse<cr>', mode = { 'n', 'x' } } },
    cmd = 'Browse',
    init = function()
      vim.g.netrw_nogx = 1
    end,
    dependencies = { 'nvim-lua/plenary.nvim' },
    opts = {
      handler_options = { search_engine = 'duckduckgo' },
    },
  },

  {
    'laytan/cloak.nvim',
    event = 'BufReadPre',
    opts = {
      cloak_telescope = true,
    },
  },
}
