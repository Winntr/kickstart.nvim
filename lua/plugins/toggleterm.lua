local function open_direction()
  local open = {}
  for _, term in ipairs(require('toggleterm.terminal').get_all()) do
    if term:is_open() then
      open[#open + 1] = term
    end
  end
  if #open == 0 then
    return 'vertical'
  end
  return open[#open].direction
end

local function next_terminal_id()
  local all = require('toggleterm.terminal').get_all(true)
  for index, term in ipairs(all) do
    if index ~= term.id then
      return index
    end
  end
  return #all + 1
end

local function new_vsplit_terminal()
  require('toggleterm').toggle(next_terminal_id(), nil, nil, open_direction())
end

local function term_id(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  local id = vim.api.nvim_buf_get_name(buf):match('toggleterm/%d+/(%d+)$')
  return id and tonumber(id) or nil
end

local function close_terminal(buf)
  if vim.api.nvim_get_mode().mode == 't' then
    vim.cmd.stopinsert()
  end

  buf = buf or vim.api.nvim_get_current_buf()
  if vim.bo[buf].filetype ~= 'toggleterm' then
    return
  end

  local id = term_id(buf)
  if id then
    require('toggleterm').toggle(id)
    return
  end

  vim.api.nvim_buf_delete(buf, { force = true })
end

local function map_terminal(buf)
  local opts = { buffer = buf, silent = true }

  vim.keymap.set('t', '<C-h>', [[<Cmd>wincmd h<CR>]], vim.tbl_extend('force', opts, { desc = 'Window left' }))
  vim.keymap.set('t', '<C-j>', [[<Cmd>wincmd j<CR>]], vim.tbl_extend('force', opts, { desc = 'Window down' }))
  vim.keymap.set('t', '<C-k>', [[<Cmd>wincmd k<CR>]], vim.tbl_extend('force', opts, { desc = 'Window up' }))
  vim.keymap.set('t', '<C-l>', [[<Cmd>wincmd l<CR>]], vim.tbl_extend('force', opts, { desc = 'Window right' }))

  vim.keymap.set('n', 'q', function()
    close_terminal(buf)
  end, vim.tbl_extend('force', opts, { desc = 'Close terminal' }))

  vim.keymap.set('n', '<C-\\>q', function()
    close_terminal(buf)
  end, vim.tbl_extend('force', opts, { desc = 'Close terminal' }))

  vim.keymap.set('t', '<C-\\>v', function()
    vim.cmd.stopinsert()
    new_vsplit_terminal()
  end, vim.tbl_extend('force', opts, { desc = 'New terminal (vertical split)' }))

  vim.keymap.set('t', '<C-\\>q', function()
    close_terminal(buf)
  end, vim.tbl_extend('force', opts, { desc = 'Close terminal' }))
end

return {
  {
    'akinsho/toggleterm.nvim',
    version = '*',
    keys = {
      {
        '<C-\\>',
        function()
          require('toggleterm').toggle()
        end,
        desc = 'Toggle terminal',
        mode = { 'n', 't' },
      },
      {
        '<C-\\>v',
        new_vsplit_terminal,
        desc = 'New terminal (vertical split)',
        mode = { 'n', 't' },
      },
      {
        '<C-\\>q',
        close_terminal,
        desc = 'Close terminal',
        mode = { 'n', 't' },
      },
    },
    opts = {
      size = function(term)
        if term.direction == 'horizontal' then
          return 15
        end
        return math.floor(vim.o.columns * 0.4)
      end,
      open_mapping = false,
      insert_mappings = false,
      terminal_mappings = false,
      direction = 'horizontal',
      close_on_exit = true,
      start_in_insert = true,
      persist_mode = true,
      persist_size = true,
      shade_terminals = false,
    },
    config = function(_, opts)
      local toggleterm = require 'toggleterm'
      toggleterm.setup(opts)

      vim.api.nvim_create_autocmd('TermOpen', {
        pattern = 'term://*toggleterm#*',
        callback = function(event)
          map_terminal(event.buf)
        end,
      })
    end,
  },
}
