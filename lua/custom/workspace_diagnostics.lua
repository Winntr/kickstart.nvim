--- Request LSP workspace diagnostics and open Trouble qflist when results arrive.
local M = {}

local seq = 0

---@param opts? {timeout_ms?: integer, quiet_ms?: integer}
function M.open_trouble(opts)
  opts = vim.tbl_extend('force', { timeout_ms = 8000, quiet_ms = 400 }, opts or {})
  seq = seq + 1
  local id = seq
  local done = false

  for _, client in ipairs(vim.lsp.get_clients { bufnr = 0, method = 'workspace/diagnostic' }) do
    vim.lsp.buf.workspace_diagnostics { client_id = client.id }
  end

  local group = vim.api.nvim_create_augroup('nvim_ws_diag_trouble', { clear = true })

  local function finish()
    if done or id ~= seq then
      return
    end
    done = true
    vim.api.nvim_clear_autocmds { group = group }
    vim.diagnostic.setqflist { open = false, title = 'Workspace diagnostics' }
    require('trouble').toggle('qflist')
  end

  vim.api.nvim_create_autocmd('DiagnosticChanged', {
    group = group,
    callback = function()
      vim.defer_fn(finish, opts.quiet_ms)
    end,
  })

  vim.defer_fn(finish, opts.timeout_ms)
end

return M
