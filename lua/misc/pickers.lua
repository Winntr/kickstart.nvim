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
