-- SQL: Dadbod + DBUI for DataGrip-like query workflow in Neovim
local SQL_FT = { 'sql', 'mysql', 'plsql', 'pgsql' }

local function load_local_connections()
  pcall(require, 'config.local')
end

return {
  {
    'tpope/vim-dadbod',
    lazy = true,
    cmd = 'DB',
  },

  {
    'kristijanhusak/vim-dadbod-completion',
    ft = SQL_FT,
    dependencies = { 'tpope/vim-dadbod' },
    init = function()
      vim.api.nvim_create_autocmd('FileType', {
        pattern = SQL_FT,
        callback = function()
          vim.bo.omnifunc = 'vim_dadbod_completion#omni'
        end,
      })
    end,
  },

  {
    'kristijanhusak/vim-dadbod-ui',
    lazy = true,
    cmd = {
      'DBUI',
      'DBUIToggle',
      'DBUIAddConnection',
      'DBUIFindBuffer',
      'DBUIRenameBuffer',
      'DBUILastQueryInfo',
    },
    ft = SQL_FT,
    dependencies = {
      'tpope/vim-dadbod',
      'kristijanhusak/vim-dadbod-completion',
    },
    keys = {
      { '<leader>Dt', '<cmd>DBUIToggle<cr>', desc = 'Database: Toggle UI' },
      { '<leader>Df', '<cmd>DBUIFindBuffer<cr>', desc = 'Database: Find buffer' },
      { '<leader>Dr', '<cmd>DBUIRenameBuffer<cr>', desc = 'Database: Rename buffer' },
      { '<leader>Dq', '<cmd>DBUILastQueryInfo<cr>', desc = 'Database: Last query info' },
      { '<leader>Da', '<cmd>DBUIAddConnection<cr>', desc = 'Database: Add connection' },
    },
    init = function()
      load_local_connections()

      vim.filetype.add {
        extension = {
          pgsql = 'pgsql',
          mysql = 'mysql',
          plsql = 'plsql',
        },
      }

      vim.g.db_ui_use_nerd_fonts = 1
      vim.g.db_ui_auto_execute_table_helpers = 1
      vim.g.db_ui_tmp_query_location = vim.fn.stdpath 'cache' .. '/db_ui_queries'
    end,
  },
}
