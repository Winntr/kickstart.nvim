--- Windows spawn fixes for agentic.nvim ACP stdio transport.
--- agentic spawns providers with detached=true; on Windows that can allocate
--- visible console windows (Windows Terminal tabs) for each child process.
local M = {}

local function is_acp_spawn(cmd, opts)
  if not opts or type(opts.stdio) ~= 'table' or not opts.stdio[1] then
    return false
  end

  local args = opts.args or {}
  for _, arg in ipairs(args) do
    if arg == 'acp' then
      return true
    end
  end

  if type(cmd) == 'string' then
    if cmd:match 'node%.exe$' and cmd:match 'cursor%-agent' then
      return true
    end
    if cmd:match 'cursor%-agent' or cmd:match '[\\/]agent%.cmd$' then
      return true
    end
  end

  return false
end

function M.apply()
  local uv = vim.uv or vim.loop
  if uv._agentic_acp_spawn_patched or vim.fn.has 'win32' ~= 1 then
    return
  end

  local orig_spawn = uv.spawn

  ---@diagnostic disable-next-line: duplicate-set-field
  function uv.spawn(cmd, opts, on_exit)
    if is_acp_spawn(cmd, opts) then
      opts = vim.tbl_extend('force', opts or {}, {
        hide = true,
        detached = false,
      })
    end

    return orig_spawn(cmd, opts, on_exit)
  end

  uv._agentic_acp_spawn_patched = true
end

return M
