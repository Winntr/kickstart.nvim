--- Override neovim-cursor single-<Esc> hide so Esc reaches the agent CLI.
local M = {}

local patched = {} ---@type table<integer, boolean>
local timers = {} ---@type table<integer, vim.uv.uv_timer_t?>

--- @param buf integer
--- @return boolean
function M.is_cursor_agent_buf(buf)
  if patched[buf] then
    return true
  end
  if vim.bo[buf].buftype ~= 'terminal' then
    return false
  end
  for _, m in ipairs(vim.api.nvim_buf_get_keymap(buf, 't')) do
    if m.lhs == '<Esc>' and m.desc == 'Exit terminal window' then
      return true
    end
  end
  return false
end

--- @param buf? integer
function M.patch(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  if not M.is_cursor_agent_buf(buf) or patched[buf] then
    return
  end

  pcall(vim.keymap.del, 't', '<Esc>', { buffer = buf })
  pcall(vim.keymap.del, 'n', '<Esc>', { buffer = buf })

  local timer = vim.uv.new_timer()
  timers[buf] = timer

  vim.keymap.set('t', '<Esc>', function()
    if timer:is_active() then
      timer:stop()
      return '<C-\\><C-n>'
    end
    timer:start(200, 0, function() end)
    return '<Esc>'
  end, {
    buffer = buf,
    expr = true,
    desc = 'Esc to agent; Esc Esc to normal mode',
  })

  vim.keymap.set('n', '<Esc><Esc>', function()
    require('neovim-cursor.terminal').hide()
  end, { buffer = buf, desc = 'Hide cursor agent terminal' })

  patched[buf] = true
end

vim.api.nvim_create_autocmd('BufDelete', {
  callback = function(args)
    local buf = args.buf
    local timer = timers[buf]
    if timer then
      pcall(function()
        timer:stop()
        timer:close()
      end)
      timers[buf] = nil
      patched[buf] = nil
    end
  end,
})

return M
