local augroup = function(name)
  return vim.api.nvim_create_augroup('nvim-' .. name, { clear = true })
end

vim.api.nvim_create_autocmd({ 'InsertEnter', 'InsertLeave' }, {
  group = augroup 'relativenumber',
  callback = function(ev)
    vim.opt_local.relativenumber = ev.event == 'InsertLeave'
  end,
})

vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight yanked text',
  group = augroup 'highlight-yank',
  callback = function()
    vim.hl.on_yank()
  end,
})

vim.api.nvim_create_autocmd({ 'BufRead', 'BufNewFile' }, {
  group = augroup 'indent-js-py',
  pattern = { '*.js', '*.ts', '*.py' },
  callback = function()
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
    vim.opt_local.expandtab = true
  end,
})
