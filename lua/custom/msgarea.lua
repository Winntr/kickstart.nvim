--- Helpers for dismissing and routing lightweight output through msgarea.nvim.
local M = {}

--- @return boolean
function M.available()
  if vim.fn.has 'nvim-0.12' ~= 1 then
    return false
  end
  return pcall(require, 'msgarea')
end

--- @return boolean
function M.is_open()
  if not M.available() then
    return false
  end
  local msgarea = require 'msgarea'
  return #msgarea.state.active_windows > 0
end

--- Close all msgarea windows and collapse cmdheight.
--- @return boolean closed True when at least one window was open.
function M.close()
  if not M.available() then
    return false
  end
  local msgarea = require 'msgarea'
  local had_windows = #msgarea.state.active_windows > 0
  msgarea.close_all()
  return had_windows
end

--- Clear msgarea content before reclaiming the region for another surface.
function M.reset()
  if not M.available() then
    return
  end
  require('msgarea').close_all()
end

--- Close sticky msgarea content, otherwise clear search highlights.
function M.dismiss_or_fallback()
  if M.close() then
    return
  end
  vim.cmd.nohlsearch()
end

--- Route an info line through ui2 `lua_print` -> msgarea.
--- @param msg string
function M.echo_status(msg)
  print(msg)
end

--- Route a warning through ui2 message routing.
--- @param msg string
function M.echo_warn(msg)
  vim.api.nvim_echo({ { msg, 'WarningMsg' } }, true, {})
end

--- Route an error through ui2 message routing.
--- @param msg string
function M.echo_error(msg)
  vim.api.nvim_err_writeln(msg)
end

return M
