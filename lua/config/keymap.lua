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

map('n', '<leader>f.', function()
  pickers().oldfiles()
end, { desc = 'Recent files' })

map('n', '<leader>fd', function()
  pickers().document_symbols()
end, { desc = 'Document symbols' })

map('n', '<leader>fk', function()
  pickers().keymaps()
end, { desc = 'Search keymaps' })

map('n', '<leader>fs', function()
  pickers().symbols()
end, { desc = 'Search symbols' })

map('n', '<leader>fo', '<cmd>AerialToggle!<cr>', { desc = 'Symbol outline' })

map('n', '<leader>sd', function()
  pickers().diagnostics()
end, { desc = 'Diagnostics picker' })

map('n', '<leader>sw', function()
  pickers().grep_word()
end, { desc = 'Grep word under cursor' })

map('n', '<leader>xt', '<cmd>TodoTrouble<cr>', { desc = 'Project TODOs' })

map('n', '<leader>gh', function()
  pickers().git_hunks()
end, { desc = 'Git hunks picker' })

map('n', '<leader>cr', function()
  pickers().lsp 'references'
end, { desc = 'LSP references' })

map('n', '<leader>ci', function()
  pickers().lsp 'implementation'
end, { desc = 'LSP implementation' })

map('n', '<leader>ct', function()
  pickers().lsp 'type_definition'
end, { desc = 'LSP type definition' })

map('n', '<leader>cl', function()
  vim.wo.cursorline = not vim.wo.cursorline
end, { desc = 'Toggle cursor line' })

map('n', '<leader>y', function()
  local path = vim.fn.expand '%:p'
  if path == '' then
    path = vim.fn.getcwd()
  end
  vim.fn.setreg('+', path)
  require('custom.msgarea').echo_status('Yanked: ' .. path)
end, { desc = 'Yank file path' })

map('n', '<leader>qq', function()
  local winid = vim.fn.win_findbuf(vim.fn.bufnr '[Location List]')
  if winid and #winid > 0 then
    vim.cmd.lclose()
  else
    vim.cmd.lopen()
  end
end, { desc = 'Toggle location list' })

map('n', ']q', '<cmd>cnext<cr>', { desc = 'Next quickfix item' })
map('n', '[q', '<cmd>cprev<cr>', { desc = 'Previous quickfix item' })

map('n', '<leader>e', '<cmd>Oil<cr>', { desc = 'Edit filesystem' })
map('n', '-', '<cmd>Oil<cr>', { desc = 'Oil' })

map('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Diagnostics to loclist' })
map('n', '<leader>cf', function()
  require('conform').format { async = true, lsp_fallback = true }
end, { desc = 'Format buffer' })

map('n', '<leader>sr', function()
  require('grug-far').open()
end, { desc = 'Search and replace' })

map('n', '<leader>vl', '<cmd>Lazy<cr>', { desc = 'Lazy' })
map('n', '<leader>vm', '<cmd>Mason<cr>', { desc = 'Mason' })
map('n', '<leader>vr', function()
  require('custom.usage').report()
end, { desc = 'Usage report' })

require('custom.windows').setup()
