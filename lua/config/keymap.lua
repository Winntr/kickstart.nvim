local map = vim.keymap.set

map('n', '<Esc>', function()
  require('custom.msgarea').dismiss_or_fallback()
end, { desc = 'Hide/close msgarea or clear search highlight' })
map('n', '<C-h>', '<C-w>h', { desc = 'Window left' })
map('n', '<C-j>', '<C-w>j', { desc = 'Window down' })
map('n', '<C-k>', '<C-w>k', { desc = 'Window up' })
map('n', '<C-l>', '<C-w>l', { desc = 'Window right' })

map('t', '<Esc><Esc>', function()
  local bufname = vim.api.nvim_buf_get_name(0)
  if bufname:match 'lazygit' then
    return '<Esc><Esc>'
  end
  return '<C-\\><C-n>'
end, { desc = 'Exit terminal mode', expr = true })

map('v', '>', '>gv', { desc = 'Indent and reselect' })
map('v', '<', '<gv', { desc = 'Dedent and reselect' })

local pickers = function()
  return require 'misc.pickers'
end

map('n', '<leader>ff', function()
  pickers().files()
end, { desc = 'Find files' })

map('n', '<leader>fg', function()
  pickers().grep_live()
end, { desc = 'Live grep' })

map('n', '<leader>fb', function()
  pickers().buffers()
end, { desc = 'Buffers' })

map('n', '<leader>fh', function()
  pickers().help()
end, { desc = 'Help tags' })

map('n', '<leader>fr', function()
  pickers().resume()
end, { desc = 'Resume picker' })

map('n', '<leader>fs', function()
  pickers().symbols()
end, { desc = 'Search symbols' })

map('n', '<leader>e', '<cmd>Oil<cr>', { desc = 'Edit filesystem' })
map('n', '-', '<cmd>Oil<cr>', { desc = 'Oil' })

map('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Diagnostics to loclist' })
map('n', '<leader>cf', function()
  require('conform').format { async = true, lsp_fallback = true }
end, { desc = 'Format buffer' })

map('n', '<leader>sr', function()
  require('grug-far').open()
end, { desc = 'Search and replace' })

map('n', '<leader>fo', '<cmd>AerialToggle!<cr>', { desc = 'Symbol outline' })

map('n', '<leader>vl', '<cmd>Lazy<cr>', { desc = 'Lazy' })
map('n', '<leader>vm', '<cmd>Mason<cr>', { desc = 'Mason' })

require('custom.windows').setup()
