local _99 = require '99'

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

local function is_windows()
  return vim.fn.has 'win32' == 1 or vim.fn.has 'win64' == 1
end

--- Cursor CLI (`agent`), non-interactive `--print` mode. Replaces OpenCode routing
--- to cursor-acp; talks to Cursor directly (same stack as agentic.nvim `cursor-acp`).
local function agent_bin()
  return is_windows() and 'agent.cmd' or 'agent'
end

--- `agent.cmd` runs `powershell -File cursor-agent.ps1 %*`. Cmd.exe parses the
--- generated command line before PowerShell sees it, so `<` / `>` in the prompt
--- can be treated as redirection and the user message is lost or truncated.
--- Launch `cursor-agent.ps1` via PowerShell with a proper argv list instead.
--- @return string|nil absolute path to cursor-agent.ps1 when resolvable
local function windows_cursor_agent_ps1()
  for _, exe in ipairs { 'agent.cmd', 'agent.ps1', 'agent' } do
    local p = vim.fn.exepath(exe)
    if p ~= '' then
      local dir = vim.fn.fnamemodify(p, ':h')
      local ps1 = vim.fs.joinpath(dir, 'cursor-agent.ps1')
      if vim.fn.filereadable(ps1) == 1 then
        return vim.fs.normalize(ps1)
      end
    end
  end
  return nil
end

--- @return string[]
local function agent_invocation_prefix()
  if is_windows() then
    local ps1 = windows_cursor_agent_ps1()
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
  return { agent_bin() }
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

local CursorCliAcpProvider = setmetatable({}, { __index = BaseProvider })

function CursorCliAcpProvider._build_command(_, query, context)
  local cmd = agent_invocation_prefix()
  vim.list_extend(cmd, {
    '--print',
    '--trust',
    '--model',
    context.model,
    query,
  })
  return cmd
end

function CursorCliAcpProvider._get_provider_name()
  return 'CursorCliAcpProvider'
end

function CursorCliAcpProvider._get_default_model()
  return 'composer-2-fast'
end

--- `agent --print` answers on stdout; 99 still reads `<TEMP_FILE>` after exit.
--- If the model never wrote the file (common with --print), use captured stdout.
--- @param query string
--- @param context _99.Prompt
--- @param observer _99.Providers.Observer
function CursorCliAcpProvider:make_request(query, context, observer)
  observer.on_start()

  local logger = context.logger:set_area(self:_get_provider_name())
  logger:debug('make_request', 'tmp_file', context.tmp_file)

  local stdout_chunks = {}

  local once_complete = once(function(status, text)
    observer.on_complete(status, text)
  end)

  local command = self:_build_command(query, context)
  local extra_args = context._99 and context._99.provider_extra_args or {}
  if #extra_args > 0 then
    vim.list_extend(command, extra_args)
  end
  logger:debug('make_request', 'command', command)

  local proc = vim.system(
    command,
    {
      text = true,
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

function CursorCliAcpProvider.fetch_models(callback)
  local cmd = agent_invocation_prefix()
  table.insert(cmd, 'models')
  vim.system(cmd, { text = true }, function(obj)
    vim.schedule(function()
      if obj.code ~= 0 then
        local err = vim.trim(obj.stderr ~= '' and obj.stderr or obj.stdout or '')
        callback(nil, err ~= '' and err or 'Failed to fetch models from agent')
        return
      end

      local models = parse_models(obj.stdout)
      if #models == 0 then
        callback(nil, 'No models returned from agent models')
        return
      end

      callback(models, nil)
    end)
  end)
end

_99.Providers.CursorCliAcpProvider = CursorCliAcpProvider

return CursorCliAcpProvider
