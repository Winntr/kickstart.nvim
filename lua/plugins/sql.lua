-- SQL editing in Neovim; query execution via DataGrip (your JDBC drivers + data sources)
local SQL_FT = { 'sql', 'mysql', 'plsql', 'pgsql', 'redshift' }

local DIALECT_BY_FT = {
  redshift = 'redshift',
  pgsql = 'postgres',
  mysql = 'mysql',
  plsql = 'postgres',
  sql = 'ansi',
}

return {
  {
    lazy = true,
    ft = SQL_FT,
    init = function()
      vim.filetype.add {
        extension = {
          pgsql = 'pgsql',
          mysql = 'mysql',
          plsql = 'plsql',
          ['redshift.sql'] = 'redshift',
        },
      }

      vim.api.nvim_create_autocmd('FileType', {
        pattern = SQL_FT,
        callback = function(args)
          vim.b[args.buf].sqlfluff_dialect = DIALECT_BY_FT[vim.bo[args.buf].filetype] or 'ansi'
        end,
      })
    end,
    keys = {
      {
        '<leader>Dg',
        function()
          require 'custom.datagrip'.open_file()
        end,
        desc = 'DataGrip: open this SQL file',
      },
      {
        '<leader>Dt',
        function()
          require 'custom.datagrip'.open_file()
        end,
        desc = 'DataGrip: open this SQL file',
      },
      {
        '<leader>Dp',
        function()
          require 'custom.datagrip'.open_project()
        end,
        desc = 'DataGrip: open Main project',
      },
    },
    cmd = {
      'DataGrip',
      'DataGripFile',
      'DataGripProject',
    },
    config = function()
      local dg = require 'custom.datagrip'

      vim.api.nvim_create_user_command('DataGrip', function(opts)
        if opts.args == 'project' then
          dg.open_project()
        else
          dg.open_file()
        end
      end, { nargs = '?', desc = 'Open SQL in DataGrip (optional: project)' })

      vim.api.nvim_create_user_command('DataGripFile', function()
        dg.open_file()
      end, { desc = 'Open current SQL file in DataGrip' })

      vim.api.nvim_create_user_command('DataGripProject', function()
        dg.open_project()
      end, { desc = 'Open DataGrip Main project' })
    end,
  },
}
