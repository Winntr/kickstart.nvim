vim.diagnostic.config {
  severity_sort = true,
  virtual_text = {
    source = 'if_many',
    spacing = 2,
  },
  underline = { severity = vim.diagnostic.severity.ERROR },
  signs = vim.g.have_nerd_font and {
    text = {
      [vim.diagnostic.severity.ERROR] = '󰅚 ',
      [vim.diagnostic.severity.WARN] = '󰀪 ',
      [vim.diagnostic.severity.INFO] = '󰋽 ',
      [vim.diagnostic.severity.HINT] = '󰌶 ',
    },
  } or true,
  float = { border = 'rounded', source = 'if_many' },
}

vim.filetype.add {
  extension = {
    mdc = 'markdown',
    ojs = 'javascript',
    http = 'http',
  },
}

vim.cmd.packadd 'cfilter'
