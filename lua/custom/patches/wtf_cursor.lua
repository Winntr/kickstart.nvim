local cursor_agent = require 'custom.cursor_agent'

local M = {}

local function cursor_provider()
  return {
    name = 'cursor',
    formatted_name = 'Cursor CLI',
    model_id = cursor_agent.MODEL_COMPOSER_25,
    url = '',
    headers = {},
    api_key = nil,
    format_request = function(data)
      return data
    end,
    format_response = function(response)
      return response
    end,
    format_error = function(response)
      return response
    end,
  }
end

function M.apply()
  if vim.g._wtf_cursor_patched then
    return
  end

  local providers = require 'wtf.ai.providers'
  providers.cursor = providers.cursor or cursor_provider()
  local validation = require 'wtf.validation'
  if not validation._cursor_provider_patched then
    local original_validate_opts = validation.validate_opts
    validation.validate_opts = function(opts)
      if opts and opts.provider == 'cursor' then
        local copied = vim.deepcopy(opts)
        copied.provider = 'copilot'
        return original_validate_opts(copied)
      end
      return original_validate_opts(opts)
    end
    validation._cursor_provider_patched = true
  end

  local original_client = require 'wtf.ai.client'

  package.loaded['wtf.ai.client'] = function(system, message, temperature)
    local config = require 'wtf.config'
    if config.options.provider ~= 'cursor' then
      return original_client(system, message, temperature)
    end

    local provider_cfg = config.options.providers and config.options.providers.cursor or {}
    local model_id = provider_cfg.model_id or cursor_agent.MODEL_COMPOSER_25
    local prompt = system .. '\n\n' .. message
    local command, env = cursor_agent.print_command(prompt, model_id)

    local result = vim.system(command, { text = true, env = env }):wait()
    if result.code ~= 0 then
      local err = vim.trim(result.stderr or '')
      if err == '' then
        err = 'Cursor CLI request failed'
      end
      return nil, err
    end

    local output = vim.trim(result.stdout or '')
    if output == '' then
      return nil, 'Cursor CLI returned an empty response'
    end

    return output, nil
  end

  vim.g._wtf_cursor_patched = true
end

return M
