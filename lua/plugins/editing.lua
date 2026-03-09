return {

  -- disables hungry features for files larget than 2MB
  { 'LunarVim/bigfile.nvim', event = 'BufReadPre' },

  -- add/delete/change can be done with the keymaps
  -- ys{motion}{char}, ds{char}, and cs{target}{replacement}
  -- {
  --   'kylechui/nvim-surround',
  --   event = 'VeryLazy',
  --   enabled = false,
  --   opts = {},
  -- },

  { -- generate docstrings
    'danymat/neogen',
    lazy = true,
    cmd = { 'Neogen' },
    dependencies = 'nvim-treesitter/nvim-treesitter',
    config = true,
  },

  {
    'chrishrb/gx.nvim',
    enabled = true,
    lazy = true,
    keys = { { 'gx', '<cmd>Browse<cr>', mode = { 'n', 'x' } } },
    cmd = { 'Browse' },
    init = function()
      vim.g.netrw_nogx = 1 -- disable netrw gx
    end,
    dependencies = { 'nvim-lua/plenary.nvim' },
    submodules = false, -- not needed, submodules are required only for tests
    opts = {
      handler_options = {
        -- you can select between google, bing, duckduckgo, and ecosia
        search_engine = 'duckduckgo',
      },
    },
  },

  {
    'folke/flash.nvim',
    enabled = true,
    event = 'VeryLazy',
    opts = {
      modes = {
        search = {
          enabled = false,
        },
      },
    },
    keys = {
      {
        's',
        mode = { 'n', 'x', 'o' },
        function()
          require('flash').jump()
        end,
      },
      {
        'S',
        mode = { 'o', 'x' },
        function()
          require('flash').treesitter()
        end,
      },
    },
  },

  -- search and replace (replaces spectre)
  {
    'MagicDuck/grug-far.nvim',
    cmd = 'GrugFar',
    keys = {
      { '<leader>sr', function() require('grug-far').open() end, desc = 'Search and [r]eplace (grug-far)' },
      { '<leader>srw', function() require('grug-far').open({ prefills = { search = vim.fn.expand('<cword>') } }) end, desc = 'Search [w]ord (grug-far)' },
      { '<leader>sr', function()
          require('grug-far').open({ prefills = { search = vim.fn.expand('<cword>') } })
        end, desc = 'Search selection (grug-far)', mode = 'v' },
    },
    opts = {
      headerMaxWidth = 80,
    },
  },

  {
    'echasnovski/mini.nvim',
    event = 'VeryLazy',
    config = function()
      -- Better Around/Inside textobjects
      --
      -- Examples:
      --  - va)  - [V]isually select [A]round [)]paren
      --  - yinq - [Y]ank [I]nside [N]ext [Q]uote
      --  - ci'  - [C]hange [I]nside [']quote
      require('mini.ai').setup {
        n_lines = 500,
        -- Move "next/last" off the bare a/i prefixes to avoid overlap waits
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
        mappings = {
          add = '<leader>msa', -- Add surrounding in Normal and Visual modes
          delete = '<leader>msd', -- Delete surrounding
          find = '<leader>msf', -- Find surrounding (to the right)
          find_left = '<leader>msF', -- Find surrounding (to the left)
          highlight = '<leader>msh', -- Highlight surrounding
          replace = '<leader>msr', -- Replace surrounding
        },
      }
    end,
  },

  -- visual undo history tree
  {
    'mbbill/undotree',
    cmd = 'UndotreeToggle',
    keys = {
      { '<leader>eu', '<cmd>UndotreeToggle<cr>', desc = '[u]ndotree toggle' },
    },
  },

  -- yank ring / clipboard history
  {
    'gbprod/yanky.nvim',
    event = 'VeryLazy',
    opts = {
      ring = { history_length = 50 },
      highlight = { timer = 200 },
    },
    keys = {
      { 'y', '<Plug>(YankyYank)', mode = { 'n', 'x' }, desc = 'Yank text' },
      { 'p', '<Plug>(YankyPutAfter)', mode = { 'n', 'x' }, desc = 'Put yanked text after cursor' },
      { 'P', '<Plug>(YankyPutBefore)', mode = { 'n', 'x' }, desc = 'Put yanked text before cursor' },
      { '<c-p>', '<Plug>(YankyPreviousEntry)', desc = 'Select previous yank entry' },
      { '<c-n>', '<Plug>(YankyNextEntry)', desc = 'Select next yank entry' },
      { '<leader>fy', function() require('telescope').extensions.yank_history.yank_history() end, desc = '[y]ank history' },
    },
  },

  -- language-aware refactoring
  {
    'ThePrimeagen/refactoring.nvim',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-treesitter/nvim-treesitter',
    },
    lazy = true,
    keys = {
      { '<leader>cre', function() require('refactoring').refactor('Extract Function') end, desc = '[e]xtract function', mode = 'x' },
      { '<leader>crv', function() require('refactoring').refactor('Extract Variable') end, desc = 'extract [v]ariable', mode = 'x' },
      { '<leader>cri', function() require('refactoring').refactor('Inline Variable') end, desc = '[i]nline variable', mode = { 'n', 'x' } },
      { '<leader>crb', function() require('refactoring').refactor('Extract Block') end, desc = 'extract [b]lock' },
      { '<leader>crr', function() require('telescope').extensions.refactoring.refactors() end, desc = '[r]efactor picker', mode = { 'n', 'x' } },
    },
    opts = {},
  },
}
