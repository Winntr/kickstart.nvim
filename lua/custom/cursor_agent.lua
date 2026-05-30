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
