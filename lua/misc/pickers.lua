local M = {}

local function pick_window()
  if vim.fn.has 'nvim-0.12' == 1 then
    return {
      relative = 'msgarea',
      border = { '▔', '▔', '▔', ' ', ' ', ' ', ' ', ' ' },
      height = 15,
    }
  end
  return {
    relative = 'editor',
    anchor = 'South',
    height = 15,
    border = 'rounded',
  }
end

local function reset_msgarea()
  if vim.fn.has 'nvim-0.12' == 1 then
    require('custom.msgarea').reset()
  end
end

function M.setup()
  require('mini.pick').setup {
    window = { config = pick_window() },
  }
end

local function builtin(name, opts)
  reset_msgarea()

  local pick = require 'mini.pick'
  local fn = pick.builtin[name]
  if type(fn) ~= 'function' then
    require('custom.msgarea').echo_warn('mini.pick builtin not found: ' .. name)
    return
  end
  return fn(opts)
end

local function extra_picker(fn, opts)
  reset_msgarea()
  return require('mini.extra').pickers[fn](opts or {})
end

local function extra_lsp(scope, opts)
  reset_msgarea()
  return require('mini.extra').pickers.lsp(vim.tbl_extend('force', { scope = scope }, opts or {}))
end

function M.files(opts)
  return builtin('files', opts)
end

function M.grep(opts)
  return builtin('grep', opts)
end

function M.grep_live(opts)
  return builtin('grep_live', opts)
end

function M.buffers(opts)
  return builtin('buffers', opts)
end

local function listed_buf_items()
  local cur_buf = vim.api.nvim_get_current_buf()
  local items, order = {}, {}

  for _, l in ipairs(vim.split(vim.api.nvim_exec('buffers', true), '\n')) do
    local buf_str, name = l:match('^%s*(%d+)'), l:match('"(.*)"')
    local buf_id = tonumber(buf_str)
    if buf_id and vim.api.nvim_buf_is_valid(buf_id) then
      order[#order + 1] = buf_id
      local label = name ~= '' and name or '[No Name]'
      if buf_id == cur_buf then
        label = '[+] ' .. label
      end
      items[#items + 1] = { text = label, bufnr = buf_id }
    end
  end

  return items, order
end

local function windows_for_buf(bufnr)
  local wins = {}
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(win) == bufnr then
      wins[#wins + 1] = win
    end
  end
  return wins
end

local function next_buf_in_list(bufnr, order)
  local idx
  for i, b in ipairs(order) do
    if b == bufnr then
      idx = i
      break
    end
  end
  if not idx then
    return nil
  end

  for i = idx + 1, #order do
    if order[i] ~= bufnr and vim.api.nvim_buf_is_valid(order[i]) then
      return order[i]
    end
  end
  for i = idx - 1, 1, -1 do
    if order[i] ~= bufnr and vim.api.nvim_buf_is_valid(order[i]) then
      return order[i]
    end
  end
  return nil
end

local function delete_buffer(bufnr)
  if vim.bo[bufnr].modified then
    local name = vim.api.nvim_buf_get_name(bufnr)
    if name == '' then
      name = '[No Name]'
    end
    local choice = vim.fn.confirm(string.format('Save changes to "%s"?', name), '&Yes\n&No\n&Cancel', 1)
    if choice == 0 or choice == 3 then
      return false
    end
    if choice == 1 then
      local ok, err = pcall(vim.cmd, 'write ' .. bufnr)
      if not ok then
        require('custom.msgarea').echo_warn('Save failed: ' .. tostring(err))
        return false
      end
    end
  end

  local ok, err = pcall(vim.api.nvim_buf_delete, bufnr, { force = true })
  if not ok then
    require('custom.msgarea').echo_warn('Could not close buffer: ' .. tostring(err))
    return false
  end
  return true
end

--- Close a buffer without another split's buffer filling the window.
local function smart_buf_delete(bufnr, order)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return false
  end

  local wins = windows_for_buf(bufnr)
  if #wins == 0 then
    return delete_buffer(bufnr)
  end

  local next_buf = next_buf_in_list(bufnr, order)
  for _, win in ipairs(wins) do
    vim.api.nvim_win_call(win, function()
      if next_buf then
        vim.api.nvim_win_set_buf(win, next_buf)
      else
        vim.cmd 'enew'
      end
    end)
  end

  return delete_buffer(bufnr)
end

function M.close_buffers(opts)
  reset_msgarea()

  local pick = require 'mini.pick'
  local items, order = listed_buf_items()
  if #items == 0 then
    require('custom.msgarea').echo_warn 'No listed buffers to close'
    return
  end

  local function rebuild_items()
    local new_items, new_order = listed_buf_items()
    order = new_order
    if #new_items == 0 then
      return false
    end
    pick.set_picker_items(new_items)
    return true
  end

  local function close_item(item)
    if item == nil or item.bufnr == nil then
      return false
    end

    if not smart_buf_delete(item.bufnr, order) then
      return true
    end

    return rebuild_items()
  end

  pick.start(vim.tbl_deep_extend('force', {
    source = {
      name = 'Close buffer',
      items = items,
      choose = close_item,
    },
  }, opts or {}))
end

function M.help(opts)
  return builtin('help', opts)
end

function M.resume(opts)
  return builtin('resume', opts)
end

function M.oldfiles(opts)
  return extra_picker('oldfiles', opts)
end

function M.document_symbols(opts)
  return extra_lsp('document_symbol', opts)
end

function M.diagnostics(opts)
  return extra_picker('diagnostic', opts)
end

function M.git_hunks(opts)
  return extra_picker('git_hunks', opts)
end

function M.keymaps(opts)
  return extra_picker('keymaps', opts)
end

function M.lsp(scope, opts)
  return extra_lsp(scope, opts)
end

function M.symbols(opts)
  return extra_lsp('workspace_symbol_live', opts)
end

function M.grep_word(opts)
  local word = vim.fn.expand '<cword>'
  if word == '' then
    require('custom.msgarea').echo_warn 'No word under cursor'
    return
  end
  return builtin('grep', vim.tbl_extend('force', { pattern = word }, opts or {}))
end

function M.harpoon(opts)
  reset_msgarea()

  local harpoon = require 'harpoon'
  harpoon:setup()
  local list = harpoon:list()
  local items = {}

  for i = 1, list:length() do
    local item = list:get(i)
    if item and item.value and item.value ~= '' then
      items[#items + 1] = {
        text = string.format('[%d] %s', i, item.value),
        idx = i,
      }
    end
  end

  if #items == 0 then
    require('custom.msgarea').echo_warn 'Harpoon list is empty — use <leader>ha to add files'
    return
  end

  require('mini.pick').start(vim.tbl_deep_extend('force', {
    source = {
      name = 'Harpoon',
      items = items,
      choose = function(item)
        list:select(item.idx)
      end,
    },
  }, opts or {}))
end

return M
