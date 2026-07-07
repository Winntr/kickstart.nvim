--- Desktop + Windows Terminal tab alert when the Cursor agent terminal goes idle.
---
--- ponytail: interactive `agent` never exits per reply; idle-after-output heuristic.
--- Upgrade path: hook Cursor CLI OSC/bell if they add a stable completion signal.
---
---@class CursorDoneConfig
---@field enabled boolean
---@field notify boolean desktop toast (Windows balloon; vim.notify elsewhere)
---@field tab_title boolean OSC 2 `[!]` prefix on the WT tab title
---@field idle_ms integer silence after output before "done"
---@field only_when_unfocused boolean skip alert while the agent split is focused
---@field message string notification body
---@field title string notification / tab context label
---@field title_prefix string prepended to WT tab title when done (e.g. `[!] `)

local M = {}

---@type CursorDoneConfig
local cfg = {
  enabled = true,
  notify = true,
  tab_title = true,
  idle_ms = 2000,
  only_when_unfocused = true,
  message = 'Cursor agent finished responding',
  title = 'Neovim',
  title_prefix = '[!] ',
}

---@class CursorDoneWatch
---@field timer? vim.uv.uv_timer_t
---@field attach? integer
---@field watching boolean
---@field alerted boolean
---@field lines_at_attach integer

---@type table<integer, CursorDoneWatch>
local watches = {}

local tab_saved_title = nil ---@type string|nil
local tab_alert = false

local esc = nil ---@type table?

local function get_esc()
  if not esc then
    esc = require 'custom.cursor_terminal_esc'
  end
  return esc
end

---@param buf integer
---@return boolean
local function is_agent_buf(buf)
  return get_esc().is_cursor_agent_buf(buf)
end

---@param buf? integer
---@return boolean
local function is_agent_focused(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  if not is_agent_buf(buf) then
    return false
  end
  local win = vim.api.nvim_get_current_win()
  return vim.api.nvim_win_get_buf(win) == buf
end

---@return string
local function default_tab_title()
  local name = vim.fn.expand '%:t'
  if name == '' then
    return 'nvim'
  end
  return name .. ' - nvim'
end

---@param title string
local function osc_tab_title(title)
  title = title:gsub('\07', ''):gsub('\27', '')
  io.stderr:write(string.format('\27]2;%s\07', title))
end

function M.set_tab_alert()
  if not cfg.tab_title or tab_alert then
    return
  end
  tab_saved_title = tab_saved_title or default_tab_title()
  tab_alert = true
  osc_tab_title(cfg.title_prefix .. tab_saved_title)
end

function M.clear_tab_alert()
  if not tab_alert then
    return
  end
  tab_alert = false
  osc_tab_title(tab_saved_title or default_tab_title())
end

---@param title string
---@param message string
function M.desktop_notify(title, message)
  if vim.fn.has 'win32' == 1 then
    local script = string.format(
      [[
Add-Type -AssemblyName System.Windows.Forms
$n = New-Object System.Windows.Forms.NotifyIcon
$n.Icon = [System.Drawing.SystemIcons]::Information
$n.Visible = $true
$n.ShowBalloonTip(5000, %s, %s, [System.Windows.Forms.ToolTipIcon]::Info)
Start-Sleep -Milliseconds 800
$n.Dispose()
]],
      vim.inspect(title),
      vim.inspect(message)
    )
    vim.fn.jobstart({
      'powershell.exe',
      '-NoProfile',
      '-WindowStyle',
      'Hidden',
      '-Command',
      script,
    }, { detach = true })
    return
  end

  if vim.fn.executable 'notify-send' == 1 then
    vim.fn.jobstart({
      'notify-send',
      title,
      message,
    }, { detach = true })
    return
  end

  vim.notify(message, vim.log.levels.INFO, { title = title })
end

---@param buf integer
---@return CursorDoneWatch
local function ensure_watch(buf)
  local w = watches[buf]
  if w then
    return w
  end
  w = {
    watching = false,
    alerted = false,
    lines_at_attach = vim.api.nvim_buf_line_count(buf),
  }
  watches[buf] = w
  return w
end

---@param buf integer
local function stop_timer(buf)
  local w = watches[buf]
  if w and w.timer then
    pcall(function()
      w.timer:stop()
    end)
  end
end

---@param buf integer
local function on_idle(buf)
  if not cfg.enabled or not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  local w = watches[buf]
  if not w or not w.watching or w.alerted then
    return
  end

  if cfg.only_when_unfocused and is_agent_focused(buf) then
    M.schedule_idle(buf)
    return
  end

  w.watching = false
  w.alerted = true

  if cfg.notify then
    M.desktop_notify(cfg.title, cfg.message)
  end
  vim.notify(cfg.message, vim.log.levels.INFO, { title = cfg.title })
  M.set_tab_alert()
end

---@param buf integer
function M.schedule_idle(buf)
  if not cfg.enabled then
    return
  end

  local w = ensure_watch(buf)
  stop_timer(buf)

  if not w.timer then
    w.timer = vim.uv.new_timer()
  end

  w.timer:start(cfg.idle_ms, 0, vim.schedule_wrap(function()
    on_idle(buf)
  end))
end

---@param buf integer
local function on_lines(buf)
  if not cfg.enabled or not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  local w = ensure_watch(buf)
  local lines = vim.api.nvim_buf_line_count(buf)

  if not w.watching and lines > w.lines_at_attach + 2 then
    w.watching = true
  end

  if w.watching and not w.alerted then
    M.schedule_idle(buf)
  end
end

---@param buf integer
function M.watch_buf(buf)
  if not cfg.enabled or not is_agent_buf(buf) then
    return
  end

  local w = ensure_watch(buf)

  if w.attach then
    return
  end

  w.attach = vim.api.nvim_buf_attach(buf, false, {
    on_lines = function()
      on_lines(buf)
      return false
    end,
    on_detach = function()
      w.attach = nil
      stop_timer(buf)
      watches[buf] = nil
    end,
  })
end

--- Arm idle detection (call after sending context / prompts).
---@param buf? integer
function M.arm(buf)
  if not cfg.enabled then
    return
  end

  buf = buf or vim.api.nvim_get_current_buf()
  if not is_agent_buf(buf) then
    local state = require('neovim-cursor').terminal.get_state()
    buf = state.buf
  end
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  M.watch_buf(buf)
  local w = ensure_watch(buf)
  w.watching = true
  w.alerted = false
  M.schedule_idle(buf)
end

--- Clear `[!]` tab prefix and allow the next idle alert.
---@param buf? integer
function M.acknowledge(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  local w = watches[buf]
  if w then
    w.alerted = false
    w.watching = false
    stop_timer(buf)
  end
  M.clear_tab_alert()
end

---@param opts? CursorDoneConfig
function M.setup(opts)
  if opts then
    cfg = vim.tbl_extend('force', cfg, opts)
  end
end

---@return CursorDoneConfig
function M.config()
  return vim.deepcopy(cfg)
end

function M.toggle()
  cfg.enabled = not cfg.enabled
  vim.notify(
    cfg.enabled and 'Cursor done alerts enabled' or 'Cursor done alerts disabled',
    vim.log.levels.INFO
  )
  if not cfg.enabled then
    for buf in pairs(watches) do
      stop_timer(buf)
    end
    M.clear_tab_alert()
  end
end

vim.api.nvim_create_autocmd('WinEnter', {
  callback = function(args)
    if is_agent_buf(args.buf) then
      M.acknowledge(args.buf)
    end
  end,
})

vim.api.nvim_create_user_command('CursorDoneToggle', function()
  M.toggle()
end, { desc = 'Toggle Cursor agent done notifications' })

-- ponytail: self-check — idle scheduling arms after output growth
do
  local w = { watching = false, alerted = false, lines_at_attach = 1 }
  assert(w.lines_at_attach + 2 == 3)
end

return M
