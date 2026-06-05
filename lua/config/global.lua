-- diagnostics
vim.diagnostic.config {
  virtual_text = true,
  underline = true,
  signs = true,
}

-- add new filetypes
vim.filetype.add {
  extension = {
    ojs = 'javascript',
    c3 = 'c3',
    c3i = 'c3',
    c3t = 'c3',
  },
}

-- additional builtin vim packages
-- filter quickfix list with Cfilter
vim.cmd.packadd 'cfilter'
