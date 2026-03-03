
-- Prepend mise shims to PATH
vim.env.PATH = vim.env.HOME .. "/.local/share/mise/shims:" .. vim.env.PATH

-- Set <space> as the leader key
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Set to true if you have a Nerd Font installed and selected in the terminal
vim.g.have_nerd_font = function()
  return not vim.g.vscode
end
vim.opt.termguicolors = true

-- [[ Setting options ]]
vim.opt.number = true
vim.opt.relativenumber = true
vim.api.nvim_create_autocmd('InsertEnter', { command = [[set norelativenumber]] })
vim.api.nvim_create_autocmd('InsertLeave', { command = [[set relativenumber]] })

vim.opt.mouse = 'a'
vim.opt.showmode = false


if vim.loop.os_uname().sysname == "Windows_NT" then

elseif vim.loop.os_uname().sysname == "Linux" then
  vim.schedule(function()
    -- vim.opt.clipboard = 'unnamedplus'
    vim.opt.clipboard = ''
  end)

  vim.g.clipboard = {
    name = 'OSC 52',
    copy = {
      ['+'] = require('vim.ui.clipboard.osc52').copy('+'),
      ['*'] = require('vim.ui.clipboard.osc52').copy('*'),
    },
    paste = {
      ['+'] = require('vim.ui.clipboard.osc52').paste('+'),
      ['*'] = require('vim.ui.clipboard.osc52').paste('*'),
    },
  }
end



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
  space = '·', -- every space
  tab = '»·', -- tab start + filler
  trail = '·', -- trailing spaces
  lead = '·', -- leading spaces
  nbsp = '␣',
}
vim.opt.inccommand = 'split'
vim.opt.cursorline = true
vim.opt.scrolloff = 10
vim.opt.confirm = true

if vim.fn.has 'win32' == 1 then
  vim.opt.shell = 'pwsh.exe'
  vim.opt.shellcmdflag = '-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command'
  vim.opt.shellquote = ''
  vim.opt.shellxquote = ''
  vim.opt.shellredir = '2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode'
  vim.opt.shellpipe = '2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode'
end

-- [[ Basic Keymaps ]]
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')
vim.keymap.set('n', '<leader>bd', '<cmd>bd<CR>', { desc = 'Close current buffer' })
vim.keymap.set('n', '<leader>ddw', 'viwd', { desc = 'Delete current word' })
vim.keymap.set('n', '<leader>dyw', 'viwy', { desc = 'Yank current word' })
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })
-- Double-escape to exit terminal mode (but not in lazygit)
vim.keymap.set('t', '<Esc><Esc>', function()
  local bufname = vim.api.nvim_buf_get_name(0)
  if bufname:match('lazygit') then
    -- Send actual escape keys to lazygit
    return '<Esc><Esc>'
  end
  return '<C-\\><C-n>'
end, { desc = 'Exit terminal mode', expr = true })

vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })


-- [[ Basic Autocommands ]]
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- [[ Set indentation for specific file types ]]
-- vim.api.nvim_create_autocmd({ 'FileType' }, {
--   pattern = { 'python', 'yaml' },
--   callback = function()
--     vim.opt_local.tabstop = 4
--     vim.opt_local.shiftwidth = 4
--     vim.opt_local.expandtab = true
--   end,
-- })

vim.api.nvim_create_autocmd({ 'BufRead', 'BufNewFile' }, {
  pattern = { '*.js', '*.ts', '*.py' },
  callback = function()
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
    vim.opt_local.expandtab = true
  end,
})

-- [[ Load non-plugin config files ]]
require 'config.global'
require 'config.autocommands'
-- [[ Set the runtime path for Neovim ]]
-- vim.g.python3_host_prog = vim.fn.expand("~/.local/share/nvim/venv/bin/python")
-- Check if the venv exists before setting it
local venv_python = vim.fn.expand("~/.local/share/nvim/venv/bin/python")
if vim.fn.executable(venv_python) == 1 then
    vim.g.python3_host_prog = venv_python
end
-- local user_profile = vim.fn.getenv 'USERPROFILE'

-- [[ Install `lazy.nvim` plugin manager ]]
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  local out = vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }
  if vim.v.shell_error ~= 0 then
    error('Error cloning lazy.nvim:\n' .. out)
  end
end
vim.opt.rtp:prepend(lazypath)

-- [[ Configure and install plugins ]]
-- Loads all plugin specs from lua/plugins/ folder
require('lazy').setup('plugins', {
  defaults = {
    version = false,
  },
  dev = {
    path = '~/projects',
    fallback = true,
  },
  install = {
    missing = true,
    colorscheme = { 'default' },
  },
  checker = { enabled = false },
  change_detection = {
    enabled = true,
    notify = false,
  },
  ui = {
    icons = vim.g.have_nerd_font and {} or {
      cmd = '⌘',
      config = '🛠',
      event = '📅',
      ft = '📂',
      init = '⚙',
      keys = '🗝',
      plugin = '🔌',
      runtime = '💻',
      require = '🌙',
      source = '📄',
      start = '🚀',
      task = '📌',
      lazy = '💤 ',
    },
  },
})

-- vim: ts=2 sts=2 sw=2 et
