--- Open SQL in DataGrip — uses your existing JDBC drivers and saved data sources.
--- ponytail: no jar hijacking; delegate execution to the IDE you already configured.
local M = {}

local DEFAULT_EXE = 'C:\\Program Files\\JetBrains\\DataGrip 2023.3.4\\bin\\datagrip64.exe'
local DEFAULT_PROJECT = vim.fn.expand '$USER_HOME/DataGripProjects/Main'

local function msgarea()
  return require 'custom.msgarea'
end

function M.exe()
  if vim.g.datagrip_exe then
    return vim.g.datagrip_exe
  end
  if vim.fn.executable 'datagrip' == 1 then
    return 'datagrip'
  end
  if vim.fn.executable 'datagrip64.exe' == 1 then
    return 'datagrip64.exe'
  end
  if vim.fn.executable(DEFAULT_EXE) == 1 then
    return DEFAULT_EXE
  end
  return nil
end

function M.project_path()
  return vim.g.datagrip_project or DEFAULT_PROJECT
end

function M.open_file(path, line)
  local exe = M.exe()
  if not exe then
    msgarea().echo_warn 'DataGrip not found. Set vim.g.datagrip_exe to datagrip64.exe'
    return
  end

  path = vim.fs.normalize(path or vim.api.nvim_buf_get_name(0))
  if path == '' then
    msgarea().echo_warn 'Buffer has no file path — save the file first'
    return
  end

  line = line or vim.api.nvim_win_get_cursor(0)[1]
  local cmd = { exe, '-e', '--line', tostring(line), path }
  vim.fn.jobstart(cmd, { detach = true })
end

function M.open_project()
  local exe = M.exe()
  if not exe then
    msgarea().echo_warn 'DataGrip not found. Set vim.g.datagrip_exe'
    return
  end
  local project = M.project_path()
  if vim.fn.isdirectory(project) == 0 then
    msgarea().echo_warn('DataGrip project not found: ' .. project)
    return
  end
  vim.fn.jobstart({ exe, project }, { detach = true })
end

return M
