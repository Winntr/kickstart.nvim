local M = {}

--- Kinds routed to msgarea after `msgarea.nvim` patches `msg_show`.
--- ponytail: must stay on valid ui2 targets (`cmd`) until that patch exists;
--- lazy.nvim reports spec errors before plugin `init` runs.
M.msgarea_kinds = {
  'typed_cmd',
  'wmsg',
  'emsg',
  'lua_error',
  'list_cmd',
  'lua_print',
  'echoerr',
  'shell_out',
  'shell_cmd',
  'shell_err',
}

--- @param target 'cmd'|'msgarea'
function M.set_msgarea_targets(target)
  local ok, ui2 = pcall(require, 'vim._core.ui2')
  if not ok then
    return
  end
  for _, kind in ipairs(M.msgarea_kinds) do
    ui2.cfg.msg.targets[kind] = target
  end
end

function M.setup()
  if vim.fn.has 'nvim-0.12' ~= 1 then
    return
  end

  local ok, ui2 = pcall(require, 'vim._core.ui2')
  if not ok then
    return
  end

  local targets = {
    default = 'msg',
    confirm = 'pager',
    rpc_error = 'pager',
  }
  for _, kind in ipairs(M.msgarea_kinds) do
    targets[kind] = 'cmd'
  end

  ui2.enable {
    enable = true,
    msg = {
      targets = targets,
      msg = { timeout = 4000 },
    },
  }
end

return M
