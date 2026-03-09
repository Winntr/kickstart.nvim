-- Python-specific Molten settings
-- When editing regular .py files, disable virtual text output (prefer floating window)
-- This keeps virt_text enabled for notebooks but cleaner for regular Python files

vim.schedule(function()
  -- Skip otter temp buffers
  local bufname = vim.api.nvim_buf_get_name(0)
  if bufname:match '.otter.' then
    return
  end

  -- Check if molten remote plugin is available
  -- MoltenUpdateOption only exists after :UpdateRemotePlugins has been run
  if vim.fn.exists ':MoltenInfo' == 2 then
    -- Molten commands are available, try to update options
    local ok = pcall(function()
      vim.fn.MoltenUpdateOption('virt_lines_off_by_1', false)
      vim.fn.MoltenUpdateOption('virt_text_output', false)
    end)
    if not ok then
      -- Fallback to global settings
      vim.g.molten_virt_lines_off_by_1 = false
      vim.g.molten_virt_text_output = false
    end
  else
    -- Molten not yet registered, just set globals
    vim.g.molten_virt_lines_off_by_1 = false
    vim.g.molten_virt_text_output = false
  end
end)
