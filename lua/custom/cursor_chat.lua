--- Send file/selection context to the Cursor agent terminal via @ references.
---
--- @class FileRef
--- @field path string
--- @field start_line? integer
--- @field end_line? integer
---
--- @class CursorChatConfig
--- @field command string
--- @field split table
--- @field term_opts table
--- @field keybindings? table

local M = {}

--- @type CursorChatConfig?
local config = nil

local SEND_DELAY_MS = 100

local function tabs()
  return require('neovim-cursor').tabs
end

local function terminal()
  return require('neovim-cursor').terminal
end

--- @param cfg CursorChatConfig
function M.setup(cfg)
  config = cfg
end

--- @return string|nil id
function M.ensure_agent_visible()
  if not config then
    vim.notify('cursor_chat: not configured', vim.log.levels.ERROR)
    return nil
  end

  local t = tabs()
  local term = terminal()

  if not t.has_terminals() then
    t.create_terminal(nil, config)
    return t.get_active()
  end

  local id = t.get_last() or t.get_active()
  if not id then
    t.create_terminal(nil, config)
    return t.get_active()
  end

  local state = term.get_state(id)
  if not state.is_running then
    t.create_terminal(nil, config)
    return t.get_active()
  end

  if not state.is_visible then
    term.toggle(config, id)
  end

  return t.get_active() or id
end

--- @param buf integer
--- @param start_line? integer
--- @param end_line? integer
--- @return string|nil
function M.format_ref(buf, start_line, end_line)
  local path = vim.api.nvim_buf_get_name(buf)
  if path == '' then
    vim.notify('Buffer has no file path; save it first', vim.log.levels.WARN)
    return nil
  end

  local ref = '@' .. path
  if start_line and end_line then
    local s = math.min(start_line, end_line)
    local e = math.max(start_line, end_line)
    ref = ref .. ':' .. s .. '-' .. e
  end
  return ref
end

--- @param refs string[]
function M.send_refs(refs)
  if #refs == 0 then
    return
  end

  local id = M.ensure_agent_visible()
  if not id then
    return
  end

  local text = table.concat(refs, '\n')
  vim.defer_fn(function()
    if terminal().is_running(id) then
      terminal().send_text(text, id)
    end
  end, SEND_DELAY_MS)
end

function M.send_selection()
  local buf = vim.api.nvim_get_current_buf()
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  local ref = M.format_ref(buf, start_pos[2], end_pos[2])
  if ref then
    M.send_refs({ ref })
  end
end

function M.send_current_buffer()
  local ref = M.format_ref(vim.api.nvim_get_current_buf())
  if ref then
    M.send_refs({ ref })
  end
end

function M.send_all_buffers()
  local seen = {} ---@type table<string, boolean>
  local refs = {} ---@type string[]

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buf].buftype == '' then
      local path = vim.api.nvim_buf_get_name(buf)
      if path ~= '' and not seen[path] then
        seen[path] = true
        local ref = M.format_ref(buf)
        if ref then
          refs[#refs + 1] = ref
        end
      end
    end
  end

  if #refs == 0 then
    vim.notify('No named buffers to send', vim.log.levels.INFO)
    return
  end

  M.send_refs(refs)
end

function M.focus_agent()
  local id = M.ensure_agent_visible()
  if not id then
    return
  end

  vim.schedule(function()
    local state = terminal().get_state(id)
    if state.is_visible and state.win and vim.api.nvim_win_is_valid(state.win) then
      vim.api.nvim_set_current_win(state.win)
      vim.cmd 'startinsert'
    end
  end)
end

--- @class CursorChatKeySpec
--- @field [1] string lhs
--- @field [2] fun()
--- @field mode? string|string[]
--- @field desc string

--- @param specs CursorChatKeySpec[]
function M.map(specs)
  for _, spec in ipairs(specs) do
    vim.keymap.set(spec.mode or 'n', spec[1], spec[2], {
      desc = spec.desc,
      silent = true,
    })
  end
end

return M
