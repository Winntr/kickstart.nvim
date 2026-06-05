-- set <space> as the leader key
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- set to true if you have a nerd font installed and selected in the terminal
vim.g.have_nerd_font = function()
  return not vim.g.vscode
end
vim.opt.termguicolors = true

-- [[ setting options ]]
vim.opt.number = true
vim.opt.relativenumber = true
vim.api.nvim_create_autocmd('insertenter', { command = [[set norelativenumber]] })
vim.api.nvim_create_autocmd('insertleave', { command = [[set relativenumber]] })

vim.opt.mouse = 'a'
vim.opt.showmode = false

vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.expandtab = true

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
vim.opt.autoread = true -- required for opencode.nvim events.reload

if vim.fn.has 'win32' == 1 then
  vim.opt.shell = 'pwsh.exe'
  vim.opt.shellcmdflag = '-nologo -noprofile -executionpolicy remotesigned -command'
  vim.opt.shellquote = ''
  vim.opt.shellxquote = ''
  vim.opt.shellredir = '2>&1 | out-file -encoding utf8 %s; exit $lastexitcode'
  vim.opt.shellpipe = '2>&1 | out-file -encoding utf8 %s; exit $lastexitcode'
end

-- [[ basic keymaps ]]
vim.keymap.set('n', '<esc>', '<cmd>nohlsearch<cr>')
vim.keymap.set('n', '<leader>bd', '<cmd>bd<cr>', { desc = 'close current buffer' })
vim.keymap.set('n', '<leader>ddw', 'viwd', { desc = 'delete current word' })
vim.keymap.set('n', '<leader>dyw', 'viwy', { desc = 'yank current word' })
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'open diagnostic [q]uickfix list' })
-- double-escape to exit terminal mode (but not in lazygit)
vim.keymap.set('t', '<esc><esc>', function()
  local bufname = vim.api.nvim_buf_get_name(0)
  if bufname:match 'lazygit' then
    -- send actual escape keys to lazygit
    return '<esc><esc>'
  end
  return '<c-\\><c-n>'
end, { desc = 'exit terminal mode', expr = true })

vim.keymap.set('n', '<c-h>', '<c-w><c-h>', { desc = 'move focus to the left window' })
vim.keymap.set('n', '<c-l>', '<c-w><c-l>', { desc = 'move focus to the right window' })
vim.keymap.set('n', '<c-j>', '<c-w><c-j>', { desc = 'move focus to the lower window' })
vim.keymap.set('n', '<c-k>', '<c-w><c-k>', { desc = 'move focus to the upper window' })

-- [[ basic autocommands ]]
vim.api.nvim_create_autocmd('textyankpost', {
  desc = 'highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

vim.filetype.add { extension = { mdc = 'markdown' } }

vim.api.nvim_create_autocmd({ 'bufread', 'bufnewfile' }, {
  pattern = { '*.js', '*.ts', '*.py' },
  callback = function()
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
    vim.opt_local.expandtab = true
  end,
})

-- [[ load non-plugin config files ]]
require 'config.global'
require 'config.autocommands'

-- [[ set the runtime path for neovim ]]
-- vim.g.python3_host_prog = vim.fn.expand("~/.local/share/nvim/venv/bin/python")
-- check if the venv exists before setting it (handle both unix and windows paths)
local venv_base = vim.fn.stdpath 'data' .. '/venv'
local venv_python = vim.fn.has 'win32' == 1 and venv_base .. '/scripts/python.exe' or venv_base .. '/bin/python'
if vim.fn.executable(venv_python) == 1 then
  vim.g.python3_host_prog = venv_python
end
-- local user_profile = vim.fn.getenv 'userprofile'

-- [[ install `lazy.nvim` plugin manager ]]
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  local out = vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }
  if vim.v.shell_error ~= 0 then
    error('error cloning lazy.nvim:\n' .. out)
  end
end
vim.opt.rtp:prepend(lazypath)

-- [[ configure and install plugins ]]
local plugin_imports = { { import = 'plugins' } }

-- Dynamically find all subdirectories in lua/plugins/
local plugins_path = vim.fn.stdpath 'config' .. '/lua/plugins'
if vim.fn.isdirectory(plugins_path) == 1 then
  -- Walk the directory and find subfolders
  for name, type in vim.fs.dir(plugins_path) do
    if type == 'directory' then
      table.insert(plugin_imports, { import = 'plugins.' .. name })
    end
  end
end

-- [[ configure and install plugins ]]
-- loads all plugin specs from lua/plugins/ folder
require('lazy').setup(plugin_imports, {
  -- Argument 2: Table containing your lazy configuration options
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
