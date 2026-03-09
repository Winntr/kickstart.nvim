return {
  -- Core dadbod - database interface
  {
    'tpope/vim-dadbod',
    lazy = true,
    cmd = { 'DB' },
  },

  -- UI for managing database connections and queries
  {
    'kristijanhusak/vim-dadbod-ui',
    dependencies = {
      'tpope/vim-dadbod',
      'kristijanhusak/vim-dadbod-completion',
    },
    cmd = { 'DBUI', 'DBUIToggle', 'DBUIAddConnection', 'DBUIFindBuffer' },
    keys = {
      { '<leader>Du', '<cmd>DBUIToggle<CR>', desc = 'Toggle Database UI' },
      { '<leader>Da', '<cmd>DBUIAddConnection<CR>', desc = 'Add Database Connection' },
      { '<leader>Df', '<cmd>DBUIFindBuffer<CR>', desc = 'Find Buffer in DBUI' },
      { '<leader>Dr', '<cmd>DBODBCRefresh<CR>', desc = 'Refresh ODBC Cache' },
      { '<leader>Dc', '<cmd>DBODBCClearCache<CR>', desc = 'Clear ODBC Cache' },
      { '<leader>Ds', '<cmd>DBODBCStatus<CR>', desc = 'ODBC Cache Status' },
      { '<leader>Dt', '<cmd>DBODBCTestConnection<CR>', desc = 'Test ODBC Connection' },
    },
    init = function()
      -- Use nerd fonts for icons
      vim.g.db_ui_use_nerd_fonts = 1

      -- Save queries and connections to Windows temp folder
      vim.g.db_ui_save_location = vim.fn.expand('$TEMP') .. '/nvim-db-ui'

      -- Disable postgres views for Redshift compatibility
      vim.g.db_ui_use_postgres_views = 0

      -- Show table helpers (count, keys, etc.)
      vim.g.db_ui_show_help = 1

      -- Auto-execute on save
      vim.g.db_ui_execute_on_save = 0

      -- Notification settings
      vim.g.db_ui_notification_width = 50

      -- ODBC adapter configuration
      vim.g.db_adapter_odbc_cache_ttl = 28800  -- 8 hours
      vim.g.db_adapter_odbc_exclude_system = 1  -- Exclude pg_catalog, information_schema, pg_internal
      vim.g.db_adapter_odbc_table_limit = 1000
      vim.g.db_adapter_odbc_debug = 0  -- Set to 1 for debug logging
    end,
    config = function()
      -- Helper to get current ODBC URL from DBUI or prompt
      local function get_odbc_url()
        -- Try to get current connection from DBUI
        local ok, url = pcall(function()
          return vim.b.db or vim.g.db
        end)
        
        if ok and url and url:match('^odbc://') then
          return url
        end
        
        -- Prompt user for DSN
        local dsn = vim.fn.input('ODBC DSN: ')
        if dsn == '' then
          return nil
        end
        return 'odbc://' .. dsn
      end

      -- Command: Refresh ODBC cache
      vim.api.nvim_create_user_command('DBODBCRefresh', function()
        local url = get_odbc_url()
        if not url then
          vim.notify('No ODBC connection specified', vim.log.levels.WARN)
          return
        end
        vim.fn['db#adapter#odbc#refresh'](url)
      end, { desc = 'Refresh ODBC cache for current connection' })

      -- Command: Clear ODBC cache
      vim.api.nvim_create_user_command('DBODBCClearCache', function()
        local url = get_odbc_url()
        if not url then
          vim.notify('No ODBC connection specified', vim.log.levels.WARN)
          return
        end
        vim.fn['db#adapter#odbc#clear_cache'](url)
      end, { desc = 'Clear ODBC cache for current connection' })

      -- Command: Show ODBC cache status
      vim.api.nvim_create_user_command('DBODBCStatus', function()
        local url = get_odbc_url()
        if not url then
          vim.notify('No ODBC connection specified', vim.log.levels.WARN)
          return
        end
        vim.fn['db#adapter#odbc#cache_status'](url)
      end, { desc = 'Show ODBC cache status for current connection' })

      -- Command: Test ODBC connection
      vim.api.nvim_create_user_command('DBODBCTestConnection', function()
        local url = get_odbc_url()
        if not url then
          vim.notify('No ODBC connection specified', vim.log.levels.WARN)
          return
        end
        vim.notify('Testing connection...', vim.log.levels.INFO)
        vim.fn['db#adapter#odbc#test_connection_async'](url, function(result)
          if result.success then
            vim.notify('✓ ' .. result.message, vim.log.levels.INFO)
          else
            vim.notify('✗ ' .. result.message, vim.log.levels.ERROR)
          end
        end)
      end, { desc = 'Test ODBC connection' })

      -- Command: Debug toggle
      vim.api.nvim_create_user_command('DBODBCDebug', function()
        vim.g.db_adapter_odbc_debug = vim.g.db_adapter_odbc_debug == 1 and 0 or 1
        local state = vim.g.db_adapter_odbc_debug == 1 and 'enabled' or 'disabled'
        vim.notify('ODBC debug logging ' .. state, vim.log.levels.INFO)
      end, { desc = 'Toggle ODBC adapter debug logging' })
    end,
  },

  -- SQL completion for nvim-cmp
  {
    'kristijanhusak/vim-dadbod-completion',
    ft = { 'sql', 'mysql', 'plsql' },
    dependencies = { 'tpope/vim-dadbod' },
    init = function()
      -- Set up autocmd to add dadbod completion source for SQL filetypes
      vim.api.nvim_create_autocmd('FileType', {
        pattern = { 'sql', 'mysql', 'plsql' },
        callback = function()
          -- Add vim-dadbod-completion to cmp sources for this buffer
          local cmp = require('cmp')
          cmp.setup.buffer({
            sources = cmp.config.sources({
              { name = 'vim-dadbod-completion' },
              { name = 'buffer' },
              { name = 'path' },
            })
          })
        end,
      })
    end,
  },
}
