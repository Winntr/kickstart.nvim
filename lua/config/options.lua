vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

vim.g.have_nerd_font = not vim.g.vscode
vim.g.ai_cmp = false

vim.opt.termguicolors = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = 'a'
vim.opt.showmode = false
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.expandtab = true
vim.opt.breakindent = true
vim.opt.wrap = false
vim.opt.undofile = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.signcolumn = 'yes'
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.list = true
vim.opt.listchars = {
  space = '·',
  tab = '»·',
  trail = '·',
  lead = '·',
  nbsp = '␣',
}
vim.opt.inccommand = 'split'
vim.opt.cursorline = true
vim.opt.laststatus = 3
vim.opt.scrolloff = 10
vim.opt.confirm = true
vim.opt.autoread = true

if vim.fn.has 'win32' == 1 then
  vim.opt.shell = 'pwsh.exe'
  vim.opt.shellcmdflag = '-nologo -noprofile -executionpolicy remotesigned -command'
  vim.opt.shellquote = ''
  vim.opt.shellxquote = ''
  vim.opt.shellredir = '2>&1 | out-file -encoding utf8 %s; exit $lastexitcode'
  vim.opt.shellpipe = '2>&1 | out-file -encoding utf8 %s; exit $lastexitcode'
end
