--- Overseer-style task panel built with nui.nvim.
local M = {}

local Layout = require 'nui.layout'
local Split = require 'nui.split'
local NuiTree = require 'nui.tree'
local NuiLine = require 'nui.line'
local Input = require 'nui.input'
local Menu = require 'nui.menu'

local NS = vim.api.nvim_create_namespace 'task_ui'
local PANEL_HEIGHT = 18
local TERM_HEIGHT = 8
local LIST_HEIGHT = 6

---@class TaskUiState
---@field layout NuiLayout?
---@field term_split NuiSplit?
---@field list_split NuiSplit?
---@field out_split NuiSplit?
---@field tree NuiTree?
---@field out_buf integer?
---@field term_buf integer?
---@field term_visible boolean
---@field prev_win integer?
---@field selected string?
---@field tick uv.uv_timer_t?

local state = {
  layout = nil,
  term_split = nil,
  list_split = nil,
  out_split = nil,
  tree = nil,
  out_buf = nil,
  term_buf = nil,
  term_visible = false,
  prev_win = nil,
  selected = nil,
  tick = nil,
} ---@type TaskUiState

local border = {
  style = 'rounded',
  highlight = 'FloatBorder',
}

local function tasks()
  return require 'custom.tasks'
end

local function msg()
  return require 'custom.msgarea'
end

local function valid_win(winid)
  return type(winid) == 'number' and vim.api.nvim_win_is_valid(winid)
end

--- @return boolean
function M.is_mounted()
  return state.layout ~= nil and state.layout._.mounted
end

--- @return boolean
function M.is_open()
  return M.is_mounted() and valid_win(state.list_split and state.list_split.winid)
end

--- @param name? string
--- @return boolean
function M.is_showing(name)
  if not M.is_open() then
    return false
  end
  if name then
    return state.selected == name
  end
  return state.selected ~= nil
end

--- @return string?
function M.selected()
  return state.selected
end

--- @return integer?
function M.out_win()
  local winid = state.out_split and state.out_split.winid
  if valid_win(winid) then
    return winid
  end
  return nil
end

--- @return boolean
function M.is_term_visible()
  return state.term_visible and state.term_split ~= nil and valid_win(state.term_split.winid)
end

--- @return integer?
function M.term_win()
  local winid = state.term_split and state.term_split.winid
  if valid_win(winid) then
    return winid
  end
  return nil
end

local function panel_height()
  return PANEL_HEIGHT + (state.term_visible and TERM_HEIGHT or 0)
end

local function layout_box()
  local children = {}
  if state.term_visible then
    table.insert(children, Layout.Box(state.term_split, { size = TERM_HEIGHT }))
  end
  table.insert(children, Layout.Box(state.list_split, { size = LIST_HEIGHT }))
  table.insert(children, Layout.Box(state.out_split, { grow = 1 }))
  return Layout.Box(children, { dir = 'col' })
end

local function relayout()
  if not state.layout or not state.layout._.mounted then
    return
  end
  state.layout:update({ size = panel_height() }, layout_box())
end

local function attach_shell_maps(buf)
  if vim.b[buf].task_shell_mapped then
    return
  end
  vim.b[buf].task_shell_mapped = true
  vim.keymap.set('n', 'T', function()
    M.toggle_terminal()
  end, { buffer = buf, desc = 'Toggle shell above panel', nowait = true })
  vim.keymap.set('t', 'T', function()
    vim.cmd.stopinsert()
    M.toggle_terminal()
  end, { buffer = buf, desc = 'Toggle shell above panel' })
  vim.keymap.set('n', 'q', function()
    M.close()
  end, { buffer = buf, desc = 'Close task panel', nowait = true })
  vim.keymap.set('t', '<Esc><Esc>', function()
    vim.cmd.stopinsert()
    M.close()
  end, { buffer = buf, desc = 'Close task panel' })
end

local function spawn_shell_buf(winid)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = 'hide'
  vim.bo[buf].filetype = 'task_shell'
  vim.b[buf].task_panel_shell = true
  vim.api.nvim_win_set_buf(winid, buf)
  local ok, err = pcall(function()
    vim.api.nvim_buf_call(buf, function()
      vim.fn.termopen(vim.o.shell, { cwd = tasks().workspace_root() })
    end)
  end)
  if not ok then
    msg().echo_error('tasks: shell failed: ' .. tostring(err))
    pcall(vim.api.nvim_buf_delete, buf, { force = true })
    return nil
  end
  attach_shell_maps(buf)
  state.term_buf = buf
  return buf
end

function M.hide_terminal()
  if not state.term_visible then
    return
  end
  if state.term_split then
    state.term_split:hide()
  end
  state.term_visible = false
  relayout()
end

--- @param opts? { focus?: boolean, insert?: boolean }
function M.show_terminal(opts)
  opts = opts or {}
  if not M.is_mounted() then
    M.open({ focus = false })
  end
  if state.term_visible then
    if opts.focus then
      M.focus_terminal({ insert = opts.insert })
    end
    return
  end
  state.term_visible = true
  relayout()
  state.term_split:show()
  local winid = M.term_win()
  if not winid then
    msg().echo_error 'tasks: shell window missing'
    state.term_visible = false
    return
  end
  if not state.term_buf or not vim.api.nvim_buf_is_valid(state.term_buf) then
    if not spawn_shell_buf(winid) then
      M.hide_terminal()
      return
    end
  else
    vim.api.nvim_win_set_buf(winid, state.term_buf)
    attach_shell_maps(state.term_buf)
  end
  if opts.focus then
    vim.api.nvim_set_current_win(winid)
    if opts.insert ~= false and vim.bo[state.term_buf].buftype == 'terminal' then
      vim.cmd.startinsert()
    end
  end
end

--- @param opts? { focus?: boolean, insert?: boolean }
function M.toggle_terminal(opts)
  opts = opts or {}
  if M.is_term_visible() then
    M.hide_terminal()
    return
  end
  M.show_terminal(opts)
end

--- @param opts? { focus?: boolean, insert?: boolean }
function M.focus_terminal(opts)
  opts = opts or {}
  if not M.is_term_visible() then
    M.show_terminal({ focus = opts.focus ~= false, insert = opts.insert })
    return
  end
  local winid = M.term_win()
  if winid then
    vim.api.nvim_set_current_win(winid)
    if opts.insert and vim.bo[vim.api.nvim_get_current_buf()].buftype == 'terminal' then
      vim.cmd.startinsert()
    end
  end
end

local function placeholder_lines()
  return {
    'No output for this task yet.',
    '',
    'Select a task above, then press r to run.',
  }
end

local function ensure_out_buf()
  if state.out_buf and vim.api.nvim_buf_is_valid(state.out_buf) then
    if vim.bo[state.out_buf].buftype ~= 'terminal' then
      return state.out_buf
    end
    state.out_buf = nil
  end
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = 'hide'
  vim.bo[buf].filetype = 'task_output'
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, placeholder_lines())
  vim.bo[buf].modifiable = false
  state.out_buf = buf
  return buf
end

--- @param buf integer
local function scroll_terminal_end(buf)
  if vim.bo[buf].buftype ~= 'terminal' then
    return
  end
  local winid = M.out_win()
  if not winid then
    return
  end
  if vim.api.nvim_win_get_buf(winid) ~= buf then
    return
  end
  local linecount = vim.api.nvim_buf_line_count(buf)
  if linecount > 0 then
    pcall(vim.api.nvim_win_set_cursor, winid, { linecount, 0 })
  end
end

--- @param buf integer
--- @param opts? { focus?: boolean, insert?: boolean }
function M.attach_output(buf, opts)
  opts = opts or {}
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  if not M.is_open() then
    M.open({ focus = false })
  end
  local winid = M.out_win()
  if winid then
    vim.api.nvim_win_set_buf(winid, buf)
    scroll_terminal_end(buf)
  end
  if vim.bo[buf].buftype == 'terminal' and not vim.b[buf].task_ui_mapped then
    vim.b[buf].task_ui_mapped = true
    vim.keymap.set('n', 'q', function()
      M.close()
    end, { buffer = buf, desc = 'Close task panel', nowait = true })
    vim.keymap.set('t', '<Esc><Esc>', function()
      vim.cmd.stopinsert()
      M.close()
    end, { buffer = buf, desc = 'Close task panel' })
  end
  if opts.focus and winid then
    vim.api.nvim_set_current_win(winid)
    if opts.insert and vim.bo[buf].buftype == 'terminal' then
      vim.cmd.startinsert()
    end
  end
end

function M.show_placeholder()
  if not M.is_open() then
    return
  end
  local buf = ensure_out_buf()
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, placeholder_lines())
  vim.bo[buf].modifiable = false
  M.attach_output(buf, { focus = false })
end

local function status_hl(name)
  local s = tasks().state(name)
  if s.running then
    return 'DiagnosticOk'
  end
  if s.has_terminal then
    return 'DiagnosticInfo'
  end
  return 'Comment'
end

local function status_icon(name)
  local s = tasks().state(name)
  if s.running then
    return '●'
  end
  if s.has_terminal then
    return '◐'
  end
  return '○'
end

local function build_tree_nodes()
  local nodes = {}
  for index, task in ipairs(tasks().load()) do
    table.insert(nodes, NuiTree.Node({
      id = task.name,
      task = task,
      index = index,
    }))
  end
  if #nodes == 0 then
    table.insert(nodes, NuiTree.Node({ id = '__empty__', text = 'No tasks — press a to add' }))
  end
  return nodes
end

function M.refresh_list()
  if not state.tree then
    return
  end
  state.tree:set_nodes(build_tree_nodes())
  state.tree:render()
end

--- @param name string
function M.select(name)
  state.selected = name
  M.refresh_list()
  local runtime = tasks().resolve_runtime(name)
  if runtime and vim.api.nvim_buf_is_valid(runtime.buf) then
    M.attach_output(runtime.buf, { focus = false })
  else
    M.show_placeholder()
  end
end

local function current_task()
  if not state.tree or not state.list_split then
    return nil, nil
  end
  local node = state.tree:get_node()
  if not node or not node.task then
    return nil, nil
  end
  return node.task, node.index
end

local function run_action(fn)
  local task, index = current_task()
  if not task then
    msg().echo_warn 'tasks: select a task first'
    return
  end
  M.select(task.name)
  fn(task, index)
end

--- @param task WorkspaceTask
--- @param index integer
function M.open_action_menu(task, index)
  local actions = tasks().actions_for(task)
  if #actions == 0 then
    return
  end

  M.select(task.name)

  local lines = vim.tbl_map(function(action)
    return Menu.item(action.label, { id = action.id, desc = action.desc })
  end, actions)

  local menu = Menu({
    relative = 'cursor',
    position = { row = 1, col = 0 },
    border = vim.tbl_extend('force', {}, border, {
      text = { top = ' ' .. task.name .. ' ', top_align = 'left' },
    }),
    win_options = {
      winhighlight = 'Normal:NormalFloat,FloatBorder:FloatBorder',
    },
  }, {
    lines = lines,
    max_width = 36,
    keymap = {
      focus_next = { 'j', '<Down>', '<Tab>' },
      focus_prev = { 'k', '<Up>', '<S-Tab>' },
      close = { '<Esc>', 'q' },
      submit = { '<CR>', '<Space>' },
    },
    on_submit = function(item)
      tasks().do_action(item.id, task, index)
    end,
  })

  menu:mount()
end

local function setup_list_maps()
  local function map(key, handler, desc)
    state.list_split:map('n', key, handler, { noremap = true, nowait = true, desc = desc })
  end

  map('r', function()
    run_action(function(task, index)
      tasks().start(task, index)
    end)
  end, 'Run task')

  map('s', function()
    run_action(function(task)
      tasks().stop(task.name)
    end)
  end, 'Stop task')

  map('x', function()
    run_action(function(task)
      tasks().kill(task.name)
    end)
  end, 'Kill task')

  map('R', function()
    run_action(function(task)
      tasks().restart(task.name)
    end)
  end, 'Restart task')

  map('i', function()
    run_action(function(task)
      tasks().interact(task.name)
    end)
  end, 'Interact')

  map('T', function()
    M.toggle_terminal({ focus = true })
  end, 'Toggle shell')

  map('<CR>', function()
    run_action(function(task, index)
      M.open_action_menu(task, index)
    end)
  end, 'Task actions')

  map('a', function()
    M.prompt_add()
  end, 'Add task')

  map('e', function()
    tasks().edit_file()
  end, 'Edit tasks file')

  map('q', function()
    M.close()
  end, 'Close panel')

  map('<Esc>', function()
    M.close()
  end, 'Close panel')
end

local function setup_tree()
  state.tree = NuiTree({
    bufnr = state.list_split.bufnr,
    ns_id = NS,
    nodes = build_tree_nodes(),
    get_node_id = function(node)
      return node.id
    end,
    prepare_node = function(node)
      if node.text then
        return NuiLine():append(node.text, 'Comment')
      end
      local task = node.task
      local cmd = type(task.cmd) == 'table' and table.concat(task.cmd, ' ') or task.cmd
      local line = NuiLine()
      local marker = task.name == state.selected and '▸ ' or '  '
      line:append(marker, 'Special')
      line:append(status_icon(task.name) .. ' ', status_hl(task.name))
      line:append(task.name, 'Keyword')
      line:append('  ' .. cmd, 'Comment')
      return line
    end,
    buf_options = {
      buftype = 'nofile',
      bufhidden = 'hide',
      buflisted = false,
      swapfile = false,
    },
  })
  state.tree:render()

  vim.api.nvim_create_autocmd('CursorMoved', {
    buffer = state.list_split.bufnr,
    callback = function()
      local task = current_task()
      if task and task.name ~= state.selected then
        M.select(task.name)
      end
    end,
  })
end

local function start_tick()
  if state.tick then
    return
  end
  state.tick = (vim.uv or vim.loop).new_timer()
  state.tick:start(500, 500, vim.schedule_wrap(function()
    if not M.is_open() then
      return
    end
    M.refresh_list()
    local name = state.selected
    if not name then
      return
    end
    local runtime = tasks().resolve_runtime(name)
    if runtime and vim.api.nvim_buf_is_valid(runtime.buf) then
      scroll_terminal_end(runtime.buf)
    end
  end))
end

local function stop_tick()
  if state.tick then
    state.tick:stop()
    state.tick:close()
    state.tick = nil
  end
end

local function ensure_list_ui()
  if state.tree then
    return
  end
  setup_tree()
  setup_list_maps()
end

--- @param opts { title: string, default?: string }
--- @param on_done fun(value: string?)
function M.prompt(opts, on_done)
  local default = opts.default or ''
  local finished = false
  local function finish(value)
    if finished then
      return
    end
    finished = true
    on_done(value)
  end

  local input_ui = Input({
    relative = 'editor',
    position = '50%',
    size = {
      width = math.min(80, math.max(36, vim.api.nvim_strwidth(default) + 8)),
      height = 3,
    },
    border = vim.tbl_extend('force', {}, border, {
      text = { top = ' ' .. opts.title .. ' ', top_align = 'left' },
    }),
    win_options = {
      winhighlight = 'Normal:NormalFloat,FloatBorder:FloatBorder',
    },
  }, {
    prompt = '> ',
    default_value = default,
    on_submit = function(value)
      finish(value)
    end,
    on_close = function()
      finish(nil)
    end,
  })
  input_ui:map('n', '<Esc>', function()
    input_ui:unmount()
  end, { noremap = true })
  input_ui:mount()
end

function M.prompt_add()
  M.prompt({ title = 'Task name' }, function(name)
    if not name or vim.trim(name) == '' then
      return
    end
    M.prompt({ title = 'Command' }, function(cmd)
      if not cmd or vim.trim(cmd) == '' then
        return
      end
      M.prompt({ title = 'Cwd (relative, optional)' }, function(cwd)
        tasks().add(name, cmd, cwd ~= '' and cwd or nil)
        if M.is_open() then
          M.select(name)
        end
      end)
    end)
  end)
end

local function create_layout()
  state.tree = nil
  state.term_split = Split({
    enter = false,
    focusable = true,
    border = vim.tbl_extend('force', {}, border, {
      text = { top = ' Shell ', bottom = ' T toggle · q close panel ' },
    }),
    win_options = {
      winhighlight = 'Normal:NormalFloat,FloatBorder:FloatBorder',
      number = false,
      relativenumber = false,
      signcolumn = 'no',
      wrap = false,
    },
  })

  state.list_split = Split({
    enter = false,
    focusable = true,
    border = vim.tbl_extend('force', {}, border, {
      text = { top = ' Tasks ', bottom = ' T shell · <CR> actions · r run · s stop · x kill · R restart · a add · q close ' },
    }),
    win_options = {
      winhighlight = 'Normal:NormalFloat,FloatBorder:FloatBorder,WinBar:WinBar',
      number = false,
      relativenumber = false,
      signcolumn = 'no',
      wrap = false,
      cursorline = true,
    },
  })

  state.out_split = Split({
    enter = false,
    focusable = true,
    border = vim.tbl_extend('force', {}, border, {
      text = { top = ' Output ' },
    }),
    win_options = {
      winhighlight = 'Normal:NormalFloat,FloatBorder:FloatBorder',
      number = false,
      relativenumber = false,
      signcolumn = 'no',
      wrap = false,
    },
  })

  state.layout = Layout({
    relative = 'editor',
    position = 'bottom',
    size = panel_height(),
  }, layout_box())
end

--- @param opts? { focus?: boolean }
function M.open(opts)
  opts = opts or {}

  if state.layout and state.layout._.mounted then
    state.layout:show()
  else
    state.prev_win = vim.api.nvim_get_current_win()
    create_layout()
    state.layout:mount()
  end

  ensure_list_ui()
  start_tick()

  ensure_out_buf()
  M.attach_output(state.out_buf, { focus = false })

  local loaded = tasks().load()
  if #loaded > 0 then
    M.select(loaded[1].name)
    if valid_win(state.list_split.winid) then
      vim.api.nvim_win_set_cursor(state.list_split.winid, { 1, 0 })
    end
  end

  if opts.focus and valid_win(state.list_split and state.list_split.winid) then
    vim.api.nvim_set_current_win(state.list_split.winid)
  elseif state.prev_win and vim.api.nvim_win_is_valid(state.prev_win) then
    vim.api.nvim_set_current_win(state.prev_win)
  end
end

function M.close()
  stop_tick()
  M.hide_terminal()
  if state.layout and state.layout._.mounted then
    state.layout:hide()
  end
  if state.prev_win and vim.api.nvim_win_is_valid(state.prev_win) then
    pcall(vim.api.nvim_set_current_win, state.prev_win)
  end
end

function M.toggle()
  if M.is_open() then
    M.close()
  else
    M.open({ focus = true })
  end
end

--- @param opts? { focus?: boolean, insert?: boolean }
function M.focus_output(opts)
  opts = opts or {}
  if not M.is_open() then
    M.open({ focus = opts.focus ~= false })
    return
  end
  local winid = M.out_win()
  if winid then
    vim.api.nvim_set_current_win(winid)
    if opts.insert and vim.bo[vim.api.nvim_get_current_buf()].buftype == 'terminal' then
      vim.cmd.startinsert()
    end
  end
end

return M
