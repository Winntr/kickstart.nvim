local map = vim.keymap.set

local SQL_FT = { 'sql', 'mysql', 'plsql', 'pgsql', 'redshift' }

local DIALECT_BY_FT = {
  redshift = 'redshift',
  pgsql = 'postgres',
  mysql = 'mysql',
  plsql = 'postgres',
  sql = 'ansi',
}

local function augroup(name)
  return vim.api.nvim_create_augroup('nvim-' .. name, { clear = true })
end

local function datagrip()
  return require 'custom.datagrip'
end

local function create_user_command(name, fn, opts)
  pcall(vim.api.nvim_del_user_command, name)
  vim.api.nvim_create_user_command(name, fn, opts)
end

vim.filetype.add {
  extension = {
    pgsql = 'pgsql',
    mysql = 'mysql',
    plsql = 'plsql',
    ['redshift.sql'] = 'redshift',
  },
}

vim.api.nvim_create_autocmd('FileType', {
  group = augroup 'sql-dialect',
  pattern = SQL_FT,
  callback = function(args)
    vim.b[args.buf].sqlfluff_dialect = DIALECT_BY_FT[vim.bo[args.buf].filetype] or 'ansi'
  end,
})

map('n', '<leader>Dg', function()
  datagrip().open_file()
end, { desc = 'DataGrip: open this SQL file' })

map('n', '<leader>Dt', function()
  datagrip().open_file()
end, { desc = 'DataGrip: open this SQL file' })

map('n', '<leader>Dp', function()
  datagrip().open_project()
end, { desc = 'DataGrip: open Main project' })

create_user_command('DataGrip', function(opts)
  if opts.args == 'project' then
    datagrip().open_project()
  else
    datagrip().open_file()
  end
end, { nargs = '?', desc = 'Open SQL in DataGrip (optional: project)' })

create_user_command('DataGripFile', function()
  datagrip().open_file()
end, { desc = 'Open current SQL file in DataGrip' })

create_user_command('DataGripProject', function()
  datagrip().open_project()
end, { desc = 'Open DataGrip Main project' })
