local M = {}

function M.setup()
  if vim.fn.has 'nvim-0.12' ~= 1 then
    return
  end

  local ok, ui2 = pcall(require, 'vim._core.ui2')
  if not ok then
    return
  end

  ui2.enable {
    enable = true,
    msg = {
      targets = {
        default = 'msg',
        typed_cmd = 'msgarea',
        wmsg = 'msgarea',
        emsg = 'msgarea',
        lua_error = 'msgarea',
        list_cmd = 'msgarea',
        lua_print = 'msgarea',
        echoerr = 'msgarea',
        shell_out = 'msgarea',
        shell_cmd = 'msgarea',
        shell_err = 'msgarea',
        confirm = 'pager',
        rpc_error = 'pager',
      },
      msg = { timeout = 4000 },
    },
  }
end

return M
