--- Helpers for dismissing and routing lightweight output through msgarea.nvim.
local M = {}

--- @return table?
local function view()
  local ok, mod = pcall(require, 'msgarea.view')
  return ok and mod or nil
end

--- @return boolean
local function has_windows()
  local v = view()
  if not v then
    return false
  end
  local windows = v.state.windows
  if windows.ephemeral then
    return true
  end
  return windows[1] ~= nil
end

--- @return boolean
function M.available()
  if vim.fn.has 'nvim-0.12' ~= 1 then
    return false
  end
  return pcall(require, 'msgarea')
end

--- @return boolean
function M.is_open()
  return M.available() and has_windows()
end

--- @return boolean
function M.is_visible()
  local v = view()
  if not v or not has_windows() then
    return false
  end
  return vim.o.cmdheight > v.original_cmdheight
end

--- Hide msgarea windows without destroying them (can be shown again).
--- @return boolean
function M.hide()
  if not M.available() then
    return false
  end
  if not M.is_visible() then
    return false
  end
  local v = view()
  local original = v and v.original_cmdheight or 1
  -- ponytail: upstream hide() does not collapse cmdheight unless passed explicitly
  require('msgarea').hide({ cmdheight = original })
  return true
end

--- Expand msgarea and focus it so j/k/mouse scroll work.
--- @return boolean
function M.show()
  if not M.available() then
    return false
  end
  if not has_windows() then
    vim.notify('No msgarea windows to show', vim.log.levels.WARN)
    return false
  end

  require('msgarea').show { flush = true }

  local v = view()
  local winid = v and v.state.focused
  if winid and vim.api.nvim_win_is_valid(winid) then
    vim.api.nvim_set_current_win(winid)
  end

  return true
end

--- Toggle msgarea visibility without closing buffers.
--- @return boolean visible
function M.toggle()
  if M.is_visible() then
    M.hide()
    return false
  end
  return M.show()
end

--- Close all msgarea windows and collapse cmdheight.
--- @return boolean closed True when at least one window was open.
function M.close()
  if not M.available() then
    return false
  end
  local had_windows = has_windows()
  require('msgarea').close_all()
  return had_windows
end

--- Clear msgarea content before reclaiming the region for another surface.
function M.reset()
  if not M.available() then
    return
  end
  require('msgarea').close_all()
end

--- Hide visible msgarea first; close hidden windows; else clear search highlights.
function M.dismiss_or_fallback()
  if M.is_visible() then
    M.hide()
    return
  end
  -- ponytail: cmdheight can stay expanded after a multiline error even when windows are gone
  local v = view()
  if v and vim.o.cmdheight > v.original_cmdheight then
    vim.o.cmdheight = v.original_cmdheight
    pcall(function()
      require('vim._core.ui2').cmdheight = v.original_cmdheight
    end)
    return
  end
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
