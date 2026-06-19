require 'config.options'
require 'config.global'
require 'config.autocommands'
require('config.ui2').setup()

local venv_base = vim.fn.stdpath 'data' .. '/venv'
local venv_python = vim.fn.has 'win32' == 1 and venv_base .. '/scripts/python.exe' or venv_base .. '/bin/python'
if vim.fn.executable(venv_python) == 1 then
  vim.g.python3_host_prog = venv_python
end

local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not vim.uv.fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  local out = vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }
  if vim.v.shell_error ~= 0 then
    error('error cloning lazy.nvim:\n' .. out)
  end
end
vim.opt.rtp:prepend(lazypath)

require('lazy').setup({
  { import = 'plugins' },
  { import = 'plugins.ai' },
}, {
  defaults = { version = false },
  dev = { path = '~/projects', fallback = true },
  install = { missing = true, colorscheme = { 'default' } },
  checker = { enabled = false },
  change_detection = { enabled = true, notify = false },
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

require 'config.keymap'
