--- Spawn terminal jobs in the panel output window (PTY requires a displayed buffer).
local M = {}

---@class WorkspaceTask
---@field name string
---@field cmd string|string[]
---@field cwd? string

---@class TaskRuntime
---@field name string
---@field buf integer
---@field job_id integer

---@alias TaskAction 'run' | 'show' | 'restart' | 'stop' | 'kill' | 'hide' | 'shell'

---@class TaskActionItem
---@field id TaskAction
---@field label string
---@field desc string

local ROOT_MARKERS = { '.git', 'justfile', 'Makefile', 'package.json', '.nvim' }

local last_focused ---@type string?
local runtimes = {} ---@type table<string, TaskRuntime>

local function msg()
  return require 'custom.msgarea'
end

local function ui()
  return require 'custom.tasks_ui'
end

--- @return string
function M.workspace_root()
  local cwd = vim.fn.getcwd()
  return vim.fs.root(cwd, ROOT_MARKERS) or cwd
end

--- @return string
function M.tasks_path()
  return vim.fs.joinpath(M.workspace_root(), '.nvim', 'tasks.lua')
end

--- @param task WorkspaceTask
---@return string
local function task_cwd(task)
  if task.cwd and task.cwd ~= '' then
    return vim.fs.joinpath(M.workspace_root(), task.cwd)
  end
  return M.workspace_root()
end

--- @param tasks WorkspaceTask[]
---@return boolean
local function validate_tasks(tasks)
  if type(tasks) ~= 'table' then
    return false
  end
  local names = {} ---@type table<string, boolean>
  for _, task in ipairs(tasks) do
    if type(task) ~= 'table' or type(task.name) ~= 'string' or task.name == '' then
      return false
    end
    if type(task.cmd) ~= 'string' and type(task.cmd) ~= 'table' then
      return false
    end
    if names[task.name] then
      return false
    end
    names[task.name] = true
  end
  return true
end

--- @return WorkspaceTask[]
function M.load()
  local path = M.tasks_path()
  if vim.fn.filereadable(path) == 0 then
    return {}
  end
  local chunk, err = loadfile(path)
  if not chunk then
    msg().echo_warn('tasks: failed to load ' .. path .. ': ' .. (err or 'unknown error'))
    return {}
  end
  local ok, result = pcall(chunk)
  if not ok or not validate_tasks(result) then
    msg().echo_warn('tasks: invalid format in ' .. path)
    return {}
  end
  return result
end

--- @param cmd string|string[]
--- @return string
local function serialize_cmd(cmd)
  if type(cmd) == 'string' then
    return string.format('%q', cmd)
  end
  local parts = {}
  for _, part in ipairs(cmd) do
    table.insert(parts, string.format('%q', part))
  end
  return '{ ' .. table.concat(parts, ', ') .. ' }'
end

--- @param tasks WorkspaceTask[]
function M.save(tasks)
  if not validate_tasks(tasks) then
    msg().echo_error('tasks: refused to save invalid task list')
    return
  end
  local path = M.tasks_path()
  vim.fn.mkdir(vim.fs.dirname(path), 'p')
  local lines = { '---@type WorkspaceTask[]', 'return {' }
  for _, task in ipairs(tasks) do
    local line = string.format('  { name = %q, cmd = %s', task.name, serialize_cmd(task.cmd))
    if task.cwd and task.cwd ~= '' then
      line = line .. string.format(', cwd = %q', task.cwd)
    end
    table.insert(lines, line .. ' },')
  end
  table.insert(lines, '}')
  vim.fn.writefile(lines, path)
end

--- @param name string
---@return WorkspaceTask?, integer?
function M.find_task(name)
  for index, task in ipairs(M.load()) do
    if task.name == name then
      return task, index
    end
  end
end

--- @param job_id integer
--- @return boolean
local function job_running(job_id)
  if not job_id or job_id <= 0 then
    return false
  end
  local res = vim.fn.jobwait({ job_id }, 0)
  return res[1] == -1
end

--- @param name string
---@return TaskRuntime?
function M.get_runtime(name)
  local runtime = runtimes[name]
  if runtime and vim.api.nvim_buf_is_valid(runtime.buf) then
    runtime.job_id = vim.b[runtime.buf].terminal_job_id or runtime.job_id
    return runtime
  end
  runtimes[name] = nil
  return nil
end

--- @param name string
---@return TaskRuntime?
function M.resolve_runtime(name)
  return M.get_runtime(name)
end

--- @param name string
---@return table
function M.state(name)
  local runtime = M.resolve_runtime(name)
  local has_terminal = runtime ~= nil
  local running = false
  if has_terminal then
    running = job_running(vim.b[runtime.buf].terminal_job_id)
  end
  return {
    running = running,
    has_terminal = has_terminal,
    visible = ui().is_showing(name),
  }
end

--- @param name string
---@return boolean
function M.is_running(name)
  return M.state(name).running
end

--- @param name string
---@return integer
local function create_term_buf(name)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = 'hide'
  vim.bo[buf].filetype = 'task_terminal'
  vim.b[buf].task_name = name
  return buf
end

--- @param task WorkspaceTask
---@param index integer
---@return TaskRuntime?
local function spawn(task, index)
  local existing = M.get_runtime(task.name)
  if existing and job_running(existing.job_id) then
    ui().select(task.name)
    ui().attach_output(existing.buf, { focus = false })
    ui().refresh_list()
    return existing
  end

  if existing and vim.api.nvim_buf_is_valid(existing.buf) then
    pcall(vim.api.nvim_buf_delete, existing.buf, { force = true })
    runtimes[task.name] = nil
  end

  if not ui().is_open() then
    ui().open({ focus = false })
  end
  ui().select(task.name)

  local out_win = ui().out_win()
  if not out_win then
    msg().echo_error 'tasks: output window missing'
    return nil
  end

  local buf = create_term_buf(task.name)
  local prev_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(out_win, buf)

  local job_id
  local ok, err = pcall(function()
    vim.api.nvim_buf_call(buf, function()
      job_id = vim.fn.termopen(task.cmd, { cwd = task_cwd(task) })
    end)
  end)

  if not ok then
    msg().echo_error('tasks: spawn error: ' .. tostring(err))
    pcall(vim.api.nvim_buf_delete, buf, { force = true })
    ui().show_placeholder()
    return nil
  end

  if not job_id or job_id <= 0 then
    msg().echo_error('tasks: failed to start ' .. task.name)
    pcall(vim.api.nvim_buf_delete, buf, { force = true })
    ui().show_placeholder()
    return nil
  end

  local runtime = { name = task.name, buf = buf, job_id = job_id }
  runtimes[task.name] = runtime
  last_focused = task.name

  if vim.api.nvim_win_is_valid(prev_win) then
    vim.api.nvim_set_current_win(prev_win)
  end
  ui().refresh_list()

  return runtime
end

--- @param task WorkspaceTask
---@param index? integer
---@return TaskRuntime?
function M.start(task, index)
  index = index or select(2, M.find_task(task.name)) or 1
  return spawn(task, index)
end

--- @param name string
function M.show(name)
  local task, index = M.find_task(name)
  if not task then
    msg().echo_warn('tasks: unknown task ' .. name)
    return
  end
  local runtime = M.resolve_runtime(name)
  if not runtime then
    runtime = spawn(task, index)
  end
  if not runtime then
    return
  end
  ui().select(name)
  ui().attach_output(runtime.buf, { focus = true, insert = true })
  last_focused = name
end

--- @param name string
---@return TaskRuntime?
function M.interact(name)
  local runtime = M.resolve_runtime(name)
  if not runtime then
    return nil
  end
  ui().select(name)
  ui().attach_output(runtime.buf, { focus = true, insert = true })
  last_focused = name
  return runtime
end

--- @param name string
---@return boolean
function M.stop(name)
  local runtime = M.interact(name)
  if not runtime then
    msg().echo_warn('tasks: no terminal for ' .. name)
    return false
  end
  local job_id = vim.b[runtime.buf].terminal_job_id
  if job_id and job_id > 0 then
    vim.defer_fn(function()
      if vim.api.nvim_buf_is_valid(runtime.buf) then
        pcall(vim.fn.chansend, job_id, '\003')
      end
    end, 50)
    msg().echo_status('tasks: sent stop to ' .. name .. ' — respond in output if prompted')
    return true
  end
  msg().echo_warn('tasks: no job for ' .. name)
  return false
end

--- @param name string
---@return boolean
function M.kill(name)
  local runtime = M.resolve_runtime(name)
  if not runtime then
    msg().echo_warn('tasks: no terminal for ' .. name)
    return false
  end
  local job_id = vim.b[runtime.buf].terminal_job_id
  if job_id and job_id > 0 and job_running(job_id) then
    local pid = vim.fn.jobpid(job_id)
    vim.fn.jobstop(job_id)
    if vim.fn.has 'win32' == 1 and pid and pid > 0 then
      vim.system({ 'taskkill', '/F', '/PID', tostring(pid) }, { detach = true })
    end
  end
  if vim.api.nvim_buf_is_valid(runtime.buf) then
    pcall(vim.api.nvim_buf_delete, runtime.buf, { force = true })
  end
  runtimes[name] = nil
  ui().refresh_list()
  if ui().selected() == name then
    ui().show_placeholder()
  end
  msg().echo_status('tasks: killed ' .. name)
  return true
end

--- @param name string
function M.restart(name)
  M.kill(name)
  local task, index = M.find_task(name)
  if task then
    M.start(task, index)
  end
end

--- @param task WorkspaceTask
---@return TaskActionItem[]
function M.actions_for(task)
  local s = M.state(task.name)
  local actions = {} ---@type TaskActionItem[]

  if s.running then
    if s.visible then
      table.insert(actions, {
        id = 'hide',
        label = 'Hide panel',
        desc = 'Close the task panel; the process keeps running.',
      })
    else
      table.insert(actions, {
        id = 'show',
        label = 'Show output',
        desc = 'Open the panel and focus this task output.',
      })
    end
    table.insert(actions, {
      id = 'stop',
      label = 'Stop',
      desc = 'Send Ctrl+C and focus output so you can answer y/n prompts.',
    })
    table.insert(actions, {
      id = 'restart',
      label = 'Restart',
      desc = 'Kill the process and start the task again.',
    })
    table.insert(actions, {
      id = 'kill',
      label = 'Kill',
      desc = 'Force terminate the process and close its terminal.',
    })
  elseif s.has_terminal then
    table.insert(actions, {
      id = 'show',
      label = 'Show output',
      desc = 'Show the last terminal output in the panel.',
    })
    table.insert(actions, {
      id = 'run',
      label = 'Run again',
      desc = 'Start a new run of this task.',
    })
    table.insert(actions, {
      id = 'kill',
      label = 'Close terminal',
      desc = 'Discard the stopped terminal buffer.',
    })
  else
    table.insert(actions, {
      id = 'run',
      label = 'Run',
      desc = 'Start this task.',
    })
  end

  table.insert(actions, {
    id = 'shell',
    label = ui().is_term_visible() and 'Hide shell' or 'Show shell',
    desc = 'Toggle interactive shell above the task list (project cwd).',
  })

  return actions
end

--- @param action TaskAction
--- @param task WorkspaceTask
--- @param index? integer
function M.do_action(action, task, index)
  if action == 'run' then
    M.start(task, index)
  elseif action == 'show' then
    M.show(task.name)
  elseif action == 'hide' then
    M.hide(task.name)
  elseif action == 'stop' then
    M.stop(task.name)
  elseif action == 'restart' then
    M.restart(task.name)
  elseif action == 'kill' then
    M.kill(task.name)
  elseif action == 'shell' then
    ui().toggle_terminal({ focus = true })
  end
end

function M.toggle_terminal(opts)
  ui().toggle_terminal(opts)
end

--- @param name? string
---@return boolean
function M.hide(name)
  if not ui().is_open() then
    return false
  end
  if name and ui().selected() ~= name then
    return false
  end
  ui().close()
  return true
end

function M.hide_all()
  if ui().is_open() then
    ui().close()
    return 1
  end
  return 0
end

--- @param buf? integer
---@return string?
function M.name_for_buf(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  return vim.b[buf].task_name
end

--- @return string?
function M.current_name()
  if ui().is_open() and ui().selected() then
    return ui().selected()
  end
  local from_buf = M.name_for_buf()
  if from_buf then
    return from_buf
  end
  return last_focused
end

--- @param name string
---@param cmd string
---@param cwd? string
---@return WorkspaceTask?
function M.add(name, cmd, cwd)
  name = vim.trim(name)
  cmd = vim.trim(cmd)
  if name == '' or cmd == '' then
    msg().echo_warn('tasks: name and command are required')
    return nil
  end
  local tasks = M.load()
  for _, task in ipairs(tasks) do
    if task.name == name then
      msg().echo_warn('tasks: duplicate name ' .. name)
      return nil
    end
  end
  ---@type WorkspaceTask
  local task = { name = name, cmd = cmd }
  if cwd and cwd ~= '' then
    task.cwd = cwd
  end
  table.insert(tasks, task)
  M.save(tasks)
  ui().refresh_list()
  msg().echo_status('tasks: saved ' .. name)
  return task
end

function M.edit_file()
  local path = M.tasks_path()
  vim.fn.mkdir(vim.fs.dirname(path), 'p')
  if vim.fn.filereadable(path) == 0 then
    M.save({})
  end
  vim.cmd.edit(path)
end

function M.prompt_add()
  ui().prompt_add()
end

function M.picker()
  ui().toggle()
end

function M.show_picker()
  if not ui().is_open() then
    ui().open({ focus = true })
  end
end

function M.quick_run()
  if not ui().is_open() then
    ui().open({ focus = true })
    return
  end
  local name = M.current_name()
  local task, index = M.find_task(name or '')
  if task then
    M.start(task, index)
  end
end

vim.api.nvim_create_autocmd('BufWipeout', {
  callback = function(args)
    local name = vim.b[args.buf].task_name
    if name and runtimes[name] and runtimes[name].buf == args.buf then
      runtimes[name] = nil
      vim.schedule(function()
        ui().refresh_list()
      end)
    end
  end,
})

vim.api.nvim_create_autocmd('TermClose', {
  callback = function(args)
    local name = vim.b[args.buf].task_name
    if not name then
      return
    end
    vim.schedule(function()
      ui().refresh_list()
      if ui().selected() == name and ui().is_open() then
        ui().attach_output(args.buf, { focus = false })
      end
    end)
  end,
})

return M
