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

function M.setup()
  require('mini.pick').setup {
    window = { config = pick_window() },
  }
end

local function builtin(name, opts)
  local pick = require 'mini.pick'
  local fn = pick.builtin[name]
  if type(fn) ~= 'function' then
    vim.notify('mini.pick builtin not found: ' .. name, vim.log.levels.WARN)
    return
  end
  return fn(opts)
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

return M
