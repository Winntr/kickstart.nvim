local _99 = require '99'
local cursor_agent = require 'custom.cursor_agent'

local BaseProvider = _99.Providers.BaseProvider

--- @param fn fun(...: any): nil
--- @return fun(...: any): nil
local function once(fn)
  local called = false
  return function(...)
    if called then
      return
    end
    called = true
    fn(...)
  end
end

local function parse_models(output)
  local models = {}
  for _, line in ipairs(vim.split(output or '', '\n', { trimempty = true })) do
    local id = line:match '^(%S+)%s+%-'
    if id then
      table.insert(models, id)
    end
  end
  table.sort(models)
  return models
end

--- Cursor CLI provider for 99.nvim.
--- Spawns the same Cursor Agent binary as agentic.nvim `cursor-acp`, but uses
--- `--print` subprocess mode (99's provider architecture), not stdio ACP.
local CursorCliProvider = setmetatable({}, { __index = BaseProvider })

function CursorCliProvider._build_command(_, query, context)
  return cursor_agent.print_command(query, context.model)
end

function CursorCliProvider._get_provider_name()
  return 'CursorCliProvider'
end

function CursorCliProvider._get_default_model()
  return cursor_agent.MODEL_COMPOSER_25
end

--- @param query string
--- @param context _99.Prompt
--- @param observer _99.Providers.Observer
function CursorCliProvider:make_request(query, context, observer)
  observer.on_start()

  local logger = context.logger:set_area(self:_get_provider_name())
  logger:debug('make_request', 'tmp_file', context.tmp_file)

  local stdout_chunks = {}

  local once_complete = once(function(status, text)
    observer.on_complete(status, text)
  end)

  local command, env = cursor_agent.print_command(query, context.model)
  local extra_args = context._99 and context._99.provider_extra_args or {}
  if #extra_args > 0 then
    vim.list_extend(command, extra_args)
  end
  logger:debug('make_request', 'command', command)

  local proc = vim.system(
    command,
    {
      text = true,
      env = env,
      stdout = vim.schedule_wrap(function(err, data)
        logger:debug('stdout', 'data', data)
        if context:is_cancelled() then
          once_complete('cancelled', '')
          return
        end
        if err and err ~= '' then
          logger:debug('stdout#error', 'err', err)
        end
        if not err and data then
          stdout_chunks[#stdout_chunks + 1] = data
          observer.on_stdout(data)
        end
      end),
      stderr = vim.schedule_wrap(function(err, data)
        logger:debug('stderr', 'data', data)
        if context:is_cancelled() then
          once_complete('cancelled', '')
          return
        end
        if err and err ~= '' then
          logger:debug('stderr#error', 'err', err)
        end
        if not err then
          observer.on_stderr(data)
        end
      end),
    },
    vim.schedule_wrap(function(obj)
      if context:is_cancelled() then
        once_complete('cancelled', '')
        logger:debug('on_complete: request has been cancelled')
        return
      end
      if obj.code ~= 0 then
        local str =
          string.format('process exit code: %d\n%s', obj.code, vim.inspect(obj))
        once_complete('failed', str)
        logger:fatal(
          self:_get_provider_name() .. ' make_query failed',
          'obj from results',
          obj
        )
      else
        vim.schedule(function()
          local ok, from_file = self:_retrieve_response(context)
          local from_stdout = table.concat(stdout_chunks)
          if ok and vim.trim(from_file) ~= '' then
            once_complete('success', from_file)
          elseif vim.trim(from_stdout) ~= '' then
            logger:debug(
              'retrieve_results',
              'using_stdout_fallback',
              true,
              'bytes',
              #from_stdout
            )
            once_complete('success', from_stdout)
          elseif not ok then
            once_complete(
              'failed',
              'unable to retrieve response from temp file'
            )
          else
            once_complete('success', from_file)
          end
        end)
      end
    end)
  )

  context:_set_process(proc)
end

function CursorCliProvider.fetch_models(callback)
  local command, env = cursor_agent.models_command()
  vim.system(command, { text = true, env = env }, function(obj)
    vim.schedule(function()
      if obj.code ~= 0 then
        local err = vim.trim(obj.stderr ~= '' and obj.stderr or obj.stdout or '')
        callback(nil, err ~= '' and err or 'Failed to fetch models from cursor-agent')
        return
      end

      local models = parse_models(obj.stdout)
      if #models == 0 then
        callback(nil, 'No models returned from cursor-agent models')
        return
      end

      callback(models, nil)
    end)
  end)
end

_99.Providers.CursorCliProvider = CursorCliProvider

return CursorCliProvider
