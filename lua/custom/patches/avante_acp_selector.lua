--- Avante ACP model/mode selector fixes for Cursor CLI.
--- Cursor ACP often returns empty configOptions; fall back to `cursor-agent models`
--- and static CLI modes. See: https://forum.cursor.com/t/acp-model-selection-api-removed/160063
local cursor_agent = require 'custom.cursor_agent'

local M = {}

local CURSOR_MODES = {
  { value = 'agent', name = 'Agent', description = 'Full agent with tools' },
  { value = 'plan', name = 'Plan', description = 'Read-only planning' },
  { value = 'ask', name = 'Ask', description = 'Q&A, read-only' },
}

local function utils()
  return require 'avante.utils'
end

local function config()
  return require 'avante.config'
end

local function ensure_setup()
  local Config = require 'avante.config'
  if not Config.windows then
    require('avante').setup(vim.g.avante or {})
  end
end

local function ensure_sidebar_open()
  ensure_setup()

  local avante = require 'avante'
  local sidebar = select(1, avante.get(false))

  if not sidebar then
    avante.open_sidebar { ask = false }
    sidebar = select(1, avante.get(false))
  elseif not sidebar:is_open() then
    sidebar:open { ask = false }
  end

  return sidebar
end

local function parse_models(output)
  local models = {}
  for _, line in ipairs(vim.split(output or '', '\n', { trimempty = true })) do
    local id, desc = line:match '^(%S+)%s+%-%s*(.*)$'
    if id then
      table.insert(models, { id = id, name = desc ~= '' and desc or id })
    end
  end
  return models
end

local function fetch_cli_models(callback)
  local command, env = cursor_agent.models_command()
  vim.system(command, { text = true, env = env }, function(obj)
    vim.schedule(function()
      if obj.code ~= 0 then
        callback(nil, 'Failed to list models from cursor-agent')
        return
      end
      local models = parse_models(obj.stdout)
      if #models == 0 then
        callback(nil, 'cursor-agent models returned no entries')
        return
      end
      callback(models)
    end)
  end)
end

local function session_id(sidebar)
  return sidebar.chat_history and sidebar.chat_history.acp_session_id
end

local function has_native_options(client, category)
  if not client or not client.config_options then
    return false
  end
  for _, opt in ipairs(client.config_options) do
    if opt.category == category and opt.options and #opt.options > 0 then
      return true
    end
  end
  return false
end

local function apply_config_choice(sidebar, client, category, config_id, value)
  local sid = session_id(sidebar)
  if not sid then
    utils().warn 'ACP session is not initialized yet'
    return
  end

  local function on_success(msg)
    utils().info(msg)
    if sidebar:is_open() then
      sidebar:render_result()
    end
  end

  local function on_failure(msg)
    utils().warn(msg)
  end

  client:set_config_option(sid, config_id, value, function(_, err)
    vim.schedule(function()
      if err and config_id == 'model' then
        client:set_model(sid, value, function(_, err2)
          vim.schedule(function()
            if err2 then
              on_failure(
                'Cursor ACP may not support runtime model switching. Default model is set at ACP startup via `--model`.'
              )
            else
              on_success('ACP model updated')
            end
          end)
        end)
        return
      end

      if err and config_id == 'mode' then
        client:set_mode(sid, value, function(_, err2)
          vim.schedule(function()
            if err2 then
              on_failure('Failed to set mode: ' .. (err2.message or 'unknown error'))
            else
              on_success('ACP mode updated')
            end
          end)
        end)
        return
      end

      if err then
        on_failure('Failed to set ' .. category .. ': ' .. (err.message or 'unknown error'))
      else
        on_success('ACP ' .. category .. ' updated')
      end
    end)
  end)
end

local function show_cursor_model_picker(sidebar)
  local client = sidebar.acp_client
  if not client then
    utils().warn 'ACP client is not connected'
    return
  end

  fetch_cli_models(function(models, err)
    if not models then
      utils().warn(err or 'No models available from cursor-agent')
      return
    end

    local display = vim.tbl_map(function(m)
      return m.id .. ' - ' .. m.name
    end, models)

    vim.ui.select(display, { prompt = 'Cursor model (via CLI)> ' }, function(_, idx)
      if not idx then
        return
      end
      apply_config_choice(sidebar, client, 'model', 'model', models[idx].id)
    end)
  end)
end

local function show_cursor_mode_picker(sidebar)
  local client = sidebar.acp_client
  if not client then
    utils().warn 'ACP client is not connected'
    return
  end

  local display = vim.tbl_map(function(m)
    return m.name .. ' - ' .. m.description
  end, CURSOR_MODES)

  vim.ui.select(display, { prompt = 'Cursor mode> ' }, function(_, idx)
    if not idx then
      return
    end
    apply_config_choice(sidebar, client, 'mode', 'mode', CURSOR_MODES[idx].value)
  end)
end

local function wait_for_session(sidebar, category, show_native)
  if sidebar.acp_client then
    if has_native_options(sidebar.acp_client, category) then
      show_native()
      return
    end
    if config().provider == 'cursor-acp' then
      if category == 'model' then
        show_cursor_model_picker(sidebar)
      else
        show_cursor_mode_picker(sidebar)
      end
      return
    end
  end

  sidebar:handle_submit ''

  local attempts = 0
  local timer = vim.uv.new_timer()
  if not timer then
    utils().warn 'Failed to start ACP session timer'
    return
  end

  timer:start(
    200,
    200,
    vim.schedule_wrap(function()
      attempts = attempts + 1

      if sidebar.acp_client and has_native_options(sidebar.acp_client, category) then
        timer:stop()
        timer:close()
        show_native()
        return
      end

      if
        config().provider == 'cursor-acp'
        and sidebar.acp_client
        and sidebar.acp_client:is_ready()
        and session_id(sidebar)
      then
        timer:stop()
        timer:close()
        if category == 'model' then
          show_cursor_model_picker(sidebar)
        else
          show_cursor_mode_picker(sidebar)
        end
        return
      end

      if attempts > 50 then
        timer:stop()
        timer:close()
        utils().warn 'Timed out waiting for ACP session to initialize'
      end
    end)
  )
end

function M.apply()
  local selector = package.loaded['avante.acp_config_selector']
    or require 'avante.acp_config_selector'

  if selector._nvim_cursor_acp_selector_patched then
    return
  end

  local open_orig = selector.open

  ---@param category string
  ---@param prompt_label string
  function selector.open(category, prompt_label)
    if not config().acp_providers[config().provider] then
      return open_orig(category, prompt_label)
    end

    local sidebar = ensure_sidebar_open()
    if not sidebar or not sidebar:is_open() then
      utils().warn 'Open the Avante sidebar before selecting ACP model or mode'
      return
    end

    if config().provider ~= 'cursor-acp' then
      return open_orig(category, prompt_label)
    end

    wait_for_session(sidebar, category, function()
      open_orig(category, prompt_label)
    end)
  end

  selector._nvim_cursor_acp_selector_patched = true
end

return M
