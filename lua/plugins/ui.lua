return {
  {
    'stevearc/oil.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    cmd = 'Oil',
    keys = {
      { '-', ':Oil<cr>', desc = 'Oil' },
      { '<leader>e', ':Oil<cr>', desc = 'Edit filesystem' },
    },
    opts = {
      view_options = { show_hidden = true },
      keymaps = {
        ['<C-s>'] = false,
        ['<C-h>'] = false,
        ['<C-l>'] = false,
      },
    },
  },

  {
    'folke/which-key.nvim',
    event = 'VeryLazy',
    opts = {
      delay = 300,
      icons = {
        mappings = vim.g.have_nerd_font,
      },
      spec = {
        { '<leader>f', group = 'Find' },
        { '<leader>g', group = 'Git' },
        { '<leader>h', group = 'Harpoon' },
        { '<leader>v', group = 'Plugins' },
        { '<leader>d', group = 'Debug' },
        { '<leader>x', group = 'Diagnostics' },
        { '<leader>c', group = 'Code' },
        { '<leader>s', group = 'Search' },
        { '<leader>a', group = 'Avante', icon = '󰚩 ' },
        { '<leader>9', group = '99' },
        { '<leader>e', group = 'Explorer' },
        { '<leader>q', group = 'Quickfix' },
      },
    },
    keys = {
      {
        '<leader>?',
        function()
          require('which-key').show { global = false }
        end,
        desc = 'Buffer keymaps',
      },
      {
        '<leader><leader>',
        function()
          require('which-key').show { global = true }
        end,
        desc = 'All keymaps',
      },
    },
  },

  {
    'nvim-lualine/lualine.nvim',
    event = 'VeryLazy',
    opts = {
      options = {
        section_separators = '',
        component_separators = '│',
        globalstatus = true,
        theme = 'auto',
      },
      sections = {
        lualine_a = { 'mode' },
        lualine_b = { 'branch', 'diff', 'diagnostics' },
        lualine_c = { 'filename' },
        lualine_x = { 'filetype' },
        lualine_y = { 'progress' },
        lualine_z = { 'location' },
      },
      extensions = { 'quickfix', 'lazy' },
    },
  },

  {
    'folke/trouble.nvim',
    opts = {},
    keys = {
      {
        '<leader>xx',
        function()
          require('trouble').toggle 'diagnostics'
        end,
        desc = 'Diagnostics (Trouble)',
      },
      {
        '<leader>xX',
        function()
          require('trouble').toggle 'workspace_diagnostics'
        end,
        desc = 'Workspace diagnostics',
      },
    },
  },

  {
    'lukas-reineke/indent-blankline.nvim',
    main = 'ibl',
    event = 'VeryLazy',
    opts = {
      indent = { char = '·', tab_char = '»' },
      scope = { char = '┃' },
    },
  },

  {
    'MeanderingProgrammer/render-markdown.nvim',
    ft = { 'markdown', 'Avante' },
    opts = {
      anti_conceal = { enabled = false },
      heading = { enabled = false },
      bullet = { enabled = false },
      render_modes = { 'n', 'c' },
      win_options = { conceallevel = { rendered = 2 } },
      file_types = { 'markdown', 'Avante' },
    },
  },

  {
    'stevearc/aerial.nvim',
    cmd = { 'AerialToggle', 'AerialOpen', 'AerialNavToggle' },
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
      'nvim-tree/nvim-web-devicons',
    },
    opts = {
      backends = { 'lsp', 'treesitter', 'markdown' },
      layout = { min_width = 30, default_direction = 'prefer_right' },
      attach_mode = 'global',
    },
  },

  {
    'kevinhwang91/nvim-bqf',
    ft = 'qf',
    opts = {
      auto_enable = true,
      auto_resize_height = true,
      preview = {
        auto_preview = true,
        win_height = 12,
        border = 'rounded',
      },
    },
  },
}
