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
        { '<leader>w', group = 'Windows' },
        { '<leader>s', group = 'Search' },
        { '<leader>a', group = 'Cursor Agent', icon = '󰚩 ' },
        { '<leader>9', group = '99' },
        { '<leader>e', group = 'Explorer' },
        { '<leader>q', group = 'Quickfix' },
        { '<leader>m', group = 'Msgarea' },
        { '<leader>t', group = 'Tasks' },
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
    config = function()
      local function short_path()
        local filename = vim.fn.expand '%:t'
        if filename == '' then
          return '[' .. vim.fn.fnamemodify(vim.fn.getcwd(), ':t') .. ']'
        end
        local parent = vim.fn.expand '%:p:h:t'
        if parent == '' or parent == filename then
          return filename
        end
        return parent .. '/' .. filename
      end

      local function truncated_path()
        local path = vim.fn.expand '%:p:~'
        if path == '' then
          return vim.fn.fnamemodify(vim.fn.getcwd(), ':~')
        end

        local max_len = math.floor(vim.o.columns * 0.3)
        if #path <= max_len then
          return path
        end

        local sep = vim.fn.has 'win32' == 1 and '\\' or '/'
        local parts = vim.split(path, '[/\\]')
        if #parts <= 2 then
          return '…' .. path:sub(-(max_len - 1))
        end

        local first = parts[1]
        local remaining = max_len - #first - 4
        local tail = ''
        for i = #parts, 2, -1 do
          local part = parts[i]
          if #tail + #part + 1 > remaining then
            break
          end
          tail = sep .. part .. tail
        end

        if tail ~= '' then
          return first .. sep .. '…' .. tail
        end
        return '…' .. sep .. parts[#parts]
      end

      require('lualine').setup {
        options = {
          section_separators = '',
          component_separators = '│',
          globalstatus = true,
          theme = 'auto',
        },
        sections = {
          lualine_a = { 'mode' },
          lualine_b = { 'branch', 'diff', 'diagnostics' },
          lualine_c = { short_path, truncated_path },
          lualine_x = { 'filetype' },
          lualine_y = { 'progress' },
          lualine_z = { 'location' },
        },
        inactive_sections = {
          lualine_a = {},
          lualine_b = {},
          lualine_c = { 'filename' },
          lualine_x = { 'location' },
          lualine_y = {},
          lualine_z = {},
        },
        extensions = { 'quickfix', 'lazy' },
      }
    end,
  },

  {
    'folke/trouble.nvim',
    keys = {
      {
        '<leader>xx',
        function()
          require('custom.workspace_diagnostics').open_trouble()
        end,
        desc = 'Workspace diagnostics (Trouble)',
      },
      {
        '<leader>xX',
        function()
          vim.diagnostic.setloclist { open = false, title = 'Buffer diagnostics' }
          require('trouble').toggle('loclist')
        end,
        desc = 'Buffer diagnostics (Trouble)',
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
    config = function(_, opts)
      require('render-markdown').setup(opts)
      require('custom.patches.render_markdown_treesitter').apply()
    end,
    opts = {
      anti_conceal = { enabled = false },
      heading = { enabled = false },
      bullet = { enabled = false },
      code = { disable = { 'mermaid' } },
      render_modes = { 'n', 'c' },
      win_options = { conceallevel = { rendered = 2 } },
      file_types = { 'markdown', 'Avante' },
    },
  },

  {
    'Bekaboo/dropbar.nvim',
    event = { 'BufReadPost', 'BufNewFile' },
    dependencies = {
      {
        'romgrk/fzy-lua-native',
        build = 'make',
        cond = vim.fn.has 'win32' == 0,
        optional = true,
      },
    },
    opts = {},
    keys = {
      {
        '<leader>ls',
        function()
          require('dropbar.api').pick()
        end,
        desc = 'Symbol breadcrumbs',
      },
    },
  },

  {
    'stevearc/aerial.nvim',
    cmd = { 'AerialToggle', 'AerialOpen', 'AerialNavToggle' },
    dependencies = {
      { 'nvim-treesitter/nvim-treesitter', branch = 'main', optional = true },
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
