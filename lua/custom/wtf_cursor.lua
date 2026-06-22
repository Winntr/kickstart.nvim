--- Cursor CLI backend for wtf.nvim diagnose/fix commands.
--- Uses `cursor-agent --print` (one-shot), not ACP. Reuses wtf.nvim UI utilities.
local cursor_agent = require 'custom.cursor_agent'

local M = {}

local MODEL = cursor_agent.MODEL_COMPOSER_25

--- @param system string
--- @param message string
--- @return string? text
--- @return string? error
function M.query(system, message)
  local prompt = system .. '\n\n' .. message
  local command, env = cursor_agent.print_command(prompt, MODEL)
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

local function notify_started(action)
  vim.notify(string.format('%s with Cursor CLI: %s', action, MODEL), vim.log.levels.INFO)
end

--- @param response string
--- @return table|nil
local function parse_fix_response(response)
  local cleaned = response:gsub('^```json', ''):gsub('```$', ''):gsub('^```', '')
  local ok, json = pcall(vim.json.decode, cleaned)
  if ok and json then
    return json
  end

  local parser = vim.treesitter.get_string_parser(response, 'markdown')
  local syntax_tree = parser:parse()
  if syntax_tree and syntax_tree[1] then
    local root = syntax_tree[1]:root()
    if root then
      local query = vim.treesitter.query.parse('markdown', [[(code_fence_content) @code]])
      for id, node in query:iter_captures(root, response, 0, -1) do
        if query.captures[id] == 'code' then
          local node_text = vim.treesitter.get_node_text(node, response)
          ok, json = pcall(vim.json.decode, node_text)
          if ok and json then
            return json
          end
        end
      end
    end
  end

  ok, json = pcall(vim.json.decode, response)
  if ok and json then
    return json
  end

  return nil
end

--- @param opts? table
function M.diagnose(opts)
  local hooks = require 'wtf.hooks'
  local config = require 'wtf.config'
  local popup = require 'wtf.ui.popup'
  local process_diagnostics = require 'wtf.util.process_diagnostics'
  local save_chat = require 'wtf.util.save_chat'

  hooks.run_started_hook()

  local language = config.options.language
  local system_prompt = 'You are an expert coder and helpful assistant who can help debug code diagnostics, '
    .. 'such as warning and error messages. '
    .. 'When appropriate, give solutions with code snippets as fenced codeblocks with a language identifier '
    .. 'to enable syntax highlighting. '
    .. 'Never show line numbers on solutions, so they are easily copy and pastable.'
    .. 'Always explain in '
    .. language

  local result = process_diagnostics(opts)
  if result.err then
    vim.notify(result.err, vim.log.levels.WARN)
    hooks.run_finished_hook()
    return result.err
  end

  notify_started('Diagnosing')

  local co = coroutine.create(function()
    local response, err = M.query(system_prompt, result.payload)
    if err then
      vim.notify(err, vim.log.levels.ERROR)
      hooks.run_finished_hook()
      return
    end

    save_chat(response)
    local _, popup_err = popup.show(response)
    if popup_err then
      vim.notify(popup_err, vim.log.levels.ERROR)
    end
    hooks.run_finished_hook()
  end)

  coroutine.resume(co)
end

--- @param opts? table
function M.fix(opts)
  local hooks = require 'wtf.hooks'
  local process_diagnostics = require 'wtf.util.process_diagnostics'

  hooks.run_started_hook()

  local system_prompt = 'You are a code correction tool integrated into Neovim. '
    .. 'Your ONLY task is to fix the LSP diagnostic errors in the provided code.\n\n'
    .. 'You MUST respond with valid JSON matching this exact schema:\n'
    .. '{\n'
    .. '  "code": "the corrected code here"\n'
    .. '}\n\n'
    .. 'CRITICAL RULES:\n'
    .. '1. Output ONLY valid JSON - no other text before or after\n'
    .. '2. The \'code\' field contains ONLY the fixed code WITHOUT line numbers\n'
    .. '3. NEVER include line numbers (like \'1:\', \'2:\' etc.) in the output\n'
    .. '4. NEVER add markdown, code fences, or explanations\n'
    .. '5. NEVER add functionality beyond fixing the diagnostic issue\n'
    .. '6. Preserve EXACT formatting: indentation, spacing, line breaks, tabs vs spaces\n'
    .. '7. Fix ONLY the diagnostic issue - do not refactor or improve other code\n'
    .. '8. If code is partial, work with what\'s provided - do not complete missing parts\n\n'
    .. 'NOTE: The input code may have line numbers for context, but you must NOT include them in your output.\n\n'
    .. 'If you cannot fix the code, respond with:\n'
    .. '{\n'
    .. '  "error": "reason why the code cannot be fixed"\n'
    .. '}'

  local result = process_diagnostics(opts)
  if result.err then
    vim.notify(result.err, vim.log.levels.WARN)
    hooks.run_finished_hook()
    return result.err
  end

  notify_started('Fixing')

  local co = coroutine.create(function()
    local response, err = M.query(system_prompt, result.payload)
    if err then
      vim.notify(err, vim.log.levels.ERROR)
      hooks.run_finished_hook()
      return
    end

    local parsed = parse_fix_response(response)
    if not parsed then
      vim.notify('Failed to parse AI response. Expected JSON format.', vim.log.levels.ERROR)
      hooks.run_finished_hook()
      return
    end

    if parsed.error then
      vim.notify('AI Error: ' .. parsed.error, vim.log.levels.ERROR)
      hooks.run_finished_hook()
      return
    end

    if not parsed.code then
      vim.notify('No code in AI response', vim.log.levels.ERROR)
      hooks.run_finished_hook()
      return
    end

    local fixed_lines = vim.split(parsed.code, '\n')
    vim.api.nvim_buf_set_lines(0, result.line1 - 1, result.line2, false, fixed_lines)
    vim.notify('Code fixed successfully!', vim.log.levels.INFO)
    hooks.run_finished_hook()
  end)

  coroutine.resume(co)
end

return M
