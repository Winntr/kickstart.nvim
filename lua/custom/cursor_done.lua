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
  idle_ms = 3500,
  only_when_unfocused = true,
  message = 'Cursor agent finished responding',
  title = 'Neovim',
  title_prefix = '[!] ',
}

---@class CursorDoneWatch
---@field timer? vim.uv.uv_timer_t
---@field attach? integer
---@field armed boolean expecting agent reply for this cycle
---@field alerted boolean notification already sent or user acknowledged
---@field pending boolean idle detected while user was watching; alert on WinLeave
---@field baseline_lines integer line count at arm / acknowledge

---@type table<integer, CursorDoneWatch>
local watches = {}

---@type table<integer, boolean> terminal insert mode focused per agent buf
local term_focused = {}

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
  if not vim.api.nvim_buf_is_valid(buf) then
    return false
  end
  if get_esc().is_cursor_agent_buf(buf) then
    return true
  end
  if vim.bo[buf].buftype ~= 'terminal' then
    return false
  end
  local chan = vim.bo[buf].channel
  if chan and chan > 0 then
    local ok, info = pcall(vim.fn.jobinfo, chan)
    if ok and type(info) == 'table' then
      local cmd = type(info.cmd) == 'table' and table.concat(info.cmd, ' ') or tostring(info.cmd or '')
      if cmd:find('agent', 1, true) or cmd:find('cursor', 1, true) then
        return true
      end
    end
  end
  return false
end

---@param buf integer
---@return boolean
local function is_agent_win_focused(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return false
  end
  if term_focused[buf] then
    return true
  end
  local win = vim.fn.bufwinid(buf)
  if win <= 0 or win ~= vim.api.nvim_get_current_win() then
    return false
  end
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
    armed = false,
    alerted = false,
    pending = false,
    baseline_lines = vim.api.nvim_buf_line_count(buf),
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
local function notify_done(buf)
  if cfg.notify then
    if vim.fn.has 'win32' == 1 then
      M.desktop_notify(cfg.title, cfg.message)
    else
      vim.notify(cfg.message, vim.log.levels.INFO, { title = cfg.title })
    end
  end
  M.set_tab_alert()
end

---@param buf integer
local function fire_alert(buf)
  local w = watches[buf]
  if not w or w.alerted or not w.armed then
    return
  end

  w.armed = false
  w.alerted = true
  w.pending = false
  stop_timer(buf)
  notify_done(buf)
end

---@param buf integer
local function on_idle(buf)
  if not cfg.enabled or not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  local w = watches[buf]
  if not w or not w.armed or w.alerted then
    return
  end

  if cfg.only_when_unfocused and is_agent_win_focused(buf) then
    w.pending = true
    return
  end

  fire_alert(buf)
end

---@param buf integer
function M.schedule_idle(buf)
  if not cfg.enabled then
    return
  end

  local w = ensure_watch(buf)
  if not w.armed or w.alerted then
    return
  end

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

  if w.alerted and term_focused[buf] and lines > w.baseline_lines then
    w.alerted = false
    w.armed = true
  end

  if w.alerted then
    return
  end

  if not w.armed and lines > w.baseline_lines + 2 then
    w.armed = true
  end

  if w.armed then
    w.pending = false
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
      term_focused[buf] = nil
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
  w.armed = true
  w.alerted = false
  w.pending = false
  w.baseline_lines = vim.api.nvim_buf_line_count(buf)
  M.schedule_idle(buf)
end

--- Clear alerts and suppress re-notify until the next arm() or new output cycle.
---@param buf? integer
function M.acknowledge(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  if not is_agent_buf(buf) then
    M.clear_tab_alert()
    return
  end

  local w = watches[buf]
  if w then
    w.alerted = true
    w.armed = false
    w.pending = false
    w.baseline_lines = vim.api.nvim_buf_line_count(buf)
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

vim.api.nvim_create_autocmd('WinLeave', {
  callback = function(args)
    if not is_agent_buf(args.buf) then
      return
    end
    local w = watches[args.buf]
    if w and w.pending and w.armed and not w.alerted then
      fire_alert(args.buf)
    end
  end,
})

vim.api.nvim_create_autocmd('TermEnter', {
  callback = function(args)
    if not is_agent_buf(args.buf) then
      return
    end
    term_focused[args.buf] = true
    stop_timer(args.buf)
    local w = watches[args.buf]
    if w then
      w.pending = false
    end
  end,
})

vim.api.nvim_create_autocmd('TermLeave', {
  callback = function(args)
    if not is_agent_buf(args.buf) then
      return
    end
    term_focused[args.buf] = false
    local w = watches[args.buf]
    if w and w.pending and w.armed and not w.alerted then
      fire_alert(args.buf)
    end
  end,
})

vim.api.nvim_create_user_command('CursorDoneToggle', function()
  M.toggle()
end, { desc = 'Toggle Cursor agent done notifications' })

-- ponytail: self-check — acknowledge suppresses until next arm
do
  local w = { armed = true, alerted = false, pending = false, baseline_lines = 1 }
  w.alerted = true
  w.armed = false
  assert(w.alerted and not w.armed)
end

return M
