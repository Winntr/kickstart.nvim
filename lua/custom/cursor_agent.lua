--- Shared Cursor CLI (`agent`) helpers for CodeCompanion ACP, agentic.nvim, and 99.
local M = {}

--- CLI `--model` id (see `agent models`).
M.MODEL_COMPOSER_25 = 'composer-2.5'

--- ACP session config option value: display name (not the CLI slug).
--- Cursor ACP rejects raw ids like `composer-2.5` with "Invalid model value".
M.ACP_MODEL_DISPLAY = 'Composer 2.5'

--- ACP variant id for non-fast Composer 2.5 (agentic.nvim matches option.value).
M.ACP_VARIANT_COMPOSER_25 = 'composer-2.5'

local function is_windows()
  return vim.fn.has 'win32' == 1 or vim.fn.has 'win64' == 1
end

function M.is_windows()
  return is_windows()
end

function M.agent_bin()
  return is_windows() and 'agent.cmd' or 'agent'
end

--- @return string|nil
function M.windows_cursor_agent_ps1()
  for _, exe in ipairs { 'agent.cmd', 'agent.ps1', 'agent' } do
    local p = vim.fn.exepath(exe)
    if p ~= '' then
      local dir = vim.fn.fnamemodify(p, ':h')
      for _, name in ipairs { 'cursor-agent.ps1', 'agent.ps1' } do
        local ps1 = vim.fs.joinpath(dir, name)
        if vim.fn.filereadable(ps1) == 1 then
          return vim.fs.normalize(ps1)
        end
      end
    end
  end
  return nil
end

--- Latest Cursor Agent node entrypoint on Windows.
--- @return string|nil node
--- @return string|nil index_js
function M.windows_node_entrypoint()
  local base_path = vim.fn.expand '~/AppData/Local/cursor-agent/versions/'
  local versions = {}
  local uv = vim.uv
  local req = uv.fs_scandir(base_path)

  if req then
    while true do
      local name, entry_type = uv.fs_scandir_next(req)
      if not name then
        break
      end

      if entry_type == 'directory' and not name:match '%.zip$' then
        local node = base_path .. name .. '/node.exe'
        if vim.fn.filereadable(node) == 1 then
          table.insert(versions, name)
        end
      end
    end
  end

  if #versions == 0 then
    return nil, nil
  end

  table.sort(versions)
  local latest = versions[#versions]

  return base_path .. latest .. '/node.exe', base_path .. latest .. '/index.js'
end

--- @return { command: string, args: string[], env?: table<string, string> }
function M.cursor_cli_entrypoint()
  if is_windows() then
    local node, index_js = M.windows_node_entrypoint()
    if node and index_js then
      return {
        command = node,
        args = { index_js },
        env = {
          CURSOR_INVOKED_AS = 'agent',
          NODE_COMPILE_CACHE = vim.fn.expand '~/AppData/Local/cursor-compile-cache',
        },
      }
    end
  end

  return {
    command = 'cursor-agent',
    args = {},
  }
end

--- Build argv for `cursor-agent --print` (99.nvim subprocess provider).
--- Uses the same Windows node.exe entrypoint as ACP; protocol is `--print`, not `acp`.
--- @param query string
--- @param model_id? string
--- @return string[] argv
--- @return table<string, string>|nil env
function M.print_command(query, model_id)
  model_id = model_id or M.MODEL_COMPOSER_25
  local entry = M.cursor_cli_entrypoint()
  local argv = { entry.command }
  vim.list_extend(argv, entry.args)
  vim.list_extend(argv, {
    '--trust',
    '--force',
    '--model',
    model_id,
    '--print',
    query,
  })
  return argv, entry.env
end

--- @return string[] argv
--- @return table<string, string>|nil env
function M.models_command()
  local entry = M.cursor_cli_entrypoint()
  local argv = { entry.command }
  vim.list_extend(argv, entry.args)
  table.insert(argv, 'models')
  return argv, entry.env
end

--- Provider config for ACP clients (avante.nvim, agentic.nvim).
--- On Windows, spawn node.exe directly with the `acp` subcommand. PowerShell and
--- .cmd wrappers exit early under libuv stdio spawn and break ACP initialization.
--- @return { command: string, args: string[], env?: table<string, string> }
function M.acp_provider()
  if is_windows() then
    local node, index_js = M.windows_node_entrypoint()
    if node and index_js then
      return {
        command = node,
        args = { index_js, 'acp' },
        env = {
          CURSOR_INVOKED_AS = 'agent',
          NODE_COMPILE_CACHE = vim.fn.expand '~/AppData/Local/cursor-compile-cache',
        },
      }
    end
  end

  return {
    command = 'cursor-agent',
    args = { 'acp' },
  }
end

--- @deprecated Use acp_provider()
function M.agentic_acp_provider()
  return M.acp_provider()
end

--- argv prefix for spawning `agent` (PowerShell + ps1 on Windows when available).
--- @return string[]
function M.invocation_prefix()
  if is_windows() then
    local ps1 = M.windows_cursor_agent_ps1()
    if ps1 then
      return {
        'powershell.exe',
        '-NoProfile',
        '-ExecutionPolicy',
        'Bypass',
        '-File',
        ps1,
      }
    end
  end
  return { M.agent_bin() }
end

--- Full argv to start `agent` in ACP mode with a fixed model.
--- @param model_id? string
--- @return string[]
function M.acp_command(model_id)
  model_id = model_id or M.MODEL_COMPOSER_25
  local cmd = M.invocation_prefix()
  vim.list_extend(cmd, { '--model', model_id, 'acp' })
  return cmd
end

--- CodeCompanion cursor_cli adapter defaults for a pinned model.
--- Uses the ACP variant id (same as agentic.nvim); display name is a fallback only.
--- @return table
function M.codecompanion_defaults()
  return {
    model = M.ACP_VARIANT_COMPOSER_25,
    session_config_options = {
      model = M.ACP_VARIANT_COMPOSER_25,
    },
  }
end

return M
