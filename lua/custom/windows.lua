--- Window resize, split, and buffer controls.
local M = {}

local function change_to_vsplit()
  local buf = vim.api.nvim_get_current_buf()
  vim.cmd 'close'
  vim.cmd 'vsplit'
  vim.api.nvim_set_current_buf(buf)
end

local function change_to_hsplit()
  local buf = vim.api.nvim_get_current_buf()
  vim.cmd 'close'
  vim.cmd 'split'
  vim.api.nvim_set_current_buf(buf)
end

function M.setup()
  local map = vim.keymap.set

  map('n', '<S-Up>', '<cmd>resize +2<cr>', { desc = 'Increase window height' })
  map('n', '<S-Down>', '<cmd>resize -2<cr>', { desc = 'Decrease window height' })
  map('n', '<S-Left>', '<cmd>vertical resize -2<cr>', { desc = 'Decrease window width' })
  map('n', '<S-Right>', '<cmd>vertical resize +2<cr>', { desc = 'Increase window width' })

  map('n', '<leader>wv', change_to_vsplit, { desc = 'Window vertical split' })
  map('n', '<leader>wh', change_to_hsplit, { desc = 'Window horizontal split' })
  map('n', '<leader>wd', '<C-w>c', { desc = 'Window close' })
  map('n', '<leader>w=', '<C-w>=', { desc = 'Window equalize' })
  map('n', '<leader>w+', '<cmd>resize +2<cr>', { desc = 'Window taller' })
  map('n', '<leader>w-', '<cmd>resize -2<cr>', { desc = 'Window shorter' })
  map('n', '<leader>w>', '<cmd>vertical resize +2<cr>', { desc = 'Window wider' })
  map('n', '<leader>w<', '<cmd>vertical resize -2<cr>', { desc = 'Window narrower' })

  map('n', '<leader>wb', '<cmd>bd<cr>', { desc = 'Buffer close' })
  map('n', '<leader>wB', function()
    require('misc.pickers').close_buffers()
  end, { desc = 'Buffer close picker' })
  map('n', '<leader>wn', '<cmd>bnext<cr>', { desc = 'Buffer next' })
  map('n', '<leader>wp', '<cmd>bprevious<cr>', { desc = 'Buffer previous' })

  vim.api.nvim_create_user_command('Cvsplit', change_to_vsplit, {
    desc = 'Change current buffer to vertical split',
  })
  vim.api.nvim_create_user_command('Chsplit', change_to_hsplit, {
    desc = 'Change current buffer to horizontal split',
  })
end

return M
