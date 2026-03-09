vim.b.slime_cell_delimiter = '```'

-- wrap text, but by word no character
-- indent the wrappped line
vim.wo.wrap = true
vim.wo.linebreak = true
vim.wo.breakindent = true
vim.wo.showbreak = '|'

-- Activate quarto for LSP features in code blocks (via otter.nvim)
local ok, quarto = pcall(require, 'quarto')
if ok then
  quarto.activate()
end

-- Restore molten virt_text settings for notebooks (overrides python.lua settings)
vim.schedule(function()
  local bufname = vim.api.nvim_buf_get_name(0)
  if bufname:match '.otter.' then
    return
  end

  -- Check if molten remote plugin is available
  -- MoltenUpdateOption only exists after :UpdateRemotePlugins has been run
  if vim.fn.exists ':MoltenInfo' == 2 then
    -- Molten commands are available, try to update options
    local ok = pcall(function()
      vim.fn.MoltenUpdateOption('virt_lines_off_by_1', true)
      vim.fn.MoltenUpdateOption('virt_text_output', true)
    end)
    if not ok then
      -- Fallback to global settings
      vim.g.molten_virt_lines_off_by_1 = true
      vim.g.molten_virt_text_output = true
    end
  else
    -- Molten not yet registered, just set globals
    vim.g.molten_virt_lines_off_by_1 = true
    vim.g.molten_virt_text_output = true
  end
end)
