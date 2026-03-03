-- required in which-key plugin spec in plugins/ui.lua as `require 'config.keymap'`
local wk = require 'which-key'

P = vim.print


local nmap = function(key, effect, description)
  description = description or ""
  vim.keymap.set('n', key, effect, { silent = true, noremap = true, desc=description})
end

local vmap = function(key, effect, description)
  description = description or ""
  vim.keymap.set('v', key, effect, { silent = true, noremap = true, desc=description})
end

local imap = function(key, effect, description)
  description = description or ""
  vim.keymap.set('i', key, effect, { silent = true, noremap = true, desc=description })
end

local cmap = function(key, effect, description)
  description = description or ""
  vim.keymap.set('c', key, effect, { silent = true, noremap = true, desc=description })
end

-- move in command line
cmap('<C-a>', '<Home>')

-- save with ctrl+s
-- imap('<C-s>', '<esc>:update<cr><esc>')
-- nmap('<C-s>', '<cmd>:update<cr><esc>')

-- Move between windows using <ctrl> direction
nmap('<C-j>', '<C-W>j')
nmap('<C-k>', '<C-W>k')
nmap('<C-h>', '<C-W>h')
nmap('<C-l>', '<C-W>l')

-- Resize window using <shift> arrow keys
nmap('<S-Up>', '<cmd>resize +2<CR>')
nmap('<S-Down>', '<cmd>resize -2<CR>')
nmap('<S-Left>', '<cmd>vertical resize +2<CR>')
nmap('<S-Right>', '<cmd>vertical resize -2<CR>')

-- Add undo break-points
-- imap(',', ',<c-g>u')
-- imap('.', '.<c-g>u')
-- imap(';', ';<c-g>u')
--
-- nmap('Q', '<Nop>')

-- keep selection after indent/dedent
vmap('>', '>gv')
vmap('<', '<gv')

-- move between splits and tabs
nmap('<c-h>', '<c-w>h')
nmap('<c-l>', '<c-w>l')
nmap('<c-j>', '<c-w>j')
nmap('<c-k>', '<c-w>k')
nmap('H', '<cmd>tabprevious<cr>')
nmap('L', '<cmd>tabnext<cr>')

local function toggle_light_dark_theme()
  if vim.o.background == 'light' then
    vim.o.background = 'dark'
  else
    vim.o.background = 'light'
  end
end


--- Insert code chunk of given language
--- Splits current chunk if already within a chunk
--- @param lang string
local insert_code_chunk = function(lang)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<esc>', true, false, true), 'n', true)
  local keys = [[o```{]] .. lang .. [[}<cr>```<esc>O]]
  keys = vim.api.nvim_replace_termcodes(keys, true, false, true)
  vim.api.nvim_feedkeys(keys, 'n', false)
end


local insert_py_chunk = function()
  insert_code_chunk 'python'
end

local insert_lua_chunk = function()
  insert_code_chunk 'lua'
end

local insert_bash_chunk = function()
  insert_code_chunk 'bash'
end




local function new_terminal(lang)
  vim.cmd('vsplit term://' .. lang)
end

-- ============================================================================
-- Terminal Management (ToggleTerm-like functionality using Snacks)
-- ============================================================================

-- Store for numbered terminals (like ToggleTerm's 1-9 terminals)
local terminals = {}

--- Get or create a numbered terminal
--- @param num number Terminal number (1-9)
--- @param opts table|nil { position = "bottom"|"right"|"left"|"top"|"float" }
local function get_or_create_terminal(num, opts)
  opts = opts or {}
  local position = opts.position or "bottom"

  -- Create terminal config for this number
  local term_opts = {
    win = {
      position = position,
      style = position == "float" and "float" or "terminal",
    },
  }

  -- Use Snacks.terminal with a unique identifier based on number
  -- The 'cwd' and 'env' combo creates unique terminal instances
  return Snacks.terminal.toggle(nil, vim.tbl_extend("force", term_opts, {
    cwd = vim.fn.getcwd(),
    env = { TERM_NUM = tostring(num) },
  }))
end

--- Toggle a specific numbered terminal (like ToggleTerm's <num><C-\>)
--- @param num number Terminal number
--- @param position string|nil Position for new terminal
local function toggle_terminal(num, position)
  num = num or 1
  position = position or "bottom"
  get_or_create_terminal(num, { position = position })
end

--- Spawn a new terminal with optional position and name
--- @param opts table|nil { position = "bottom"|"right"|"left"|"top"|"float", name = string }
local function term_new(opts)
  opts = opts or {}
  local position = opts.position or "bottom"
  local name = opts.name

  local win_opts = {
    position = position,
  }

  -- Set custom title via on_buf callback if name is provided
  if name then
    win_opts.on_buf = function(self)
      vim.b[self.buf].term_title = name
    end
  end

  return Snacks.terminal.open(nil, { win = win_opts })
end

--- Get all terminal buffers
--- @return table List of terminal buffer info
local function get_terminal_buffers()
  local term_bufs = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_is_loaded(buf) then
      local buftype = vim.bo[buf].buftype
      local bufname = vim.api.nvim_buf_get_name(buf)
      if buftype == "terminal" then
        -- Get terminal job info
        local job_id = vim.b[buf].terminal_job_id
        local pid = job_id and vim.fn.jobpid(job_id) or nil
        table.insert(term_bufs, {
          buf = buf,
          name = bufname,
          pid = pid,
          job_id = job_id,
        })
      end
    end
  end
  return term_bufs
end

--- Select a terminal from a picker (like ToggleTerm's TermSelect)
local function term_select()
  local term_bufs = get_terminal_buffers()

  if #term_bufs == 0 then
    vim.notify("No terminals open", vim.log.levels.INFO)
    return
  end

  -- Try to use Snacks picker first, fall back to vim.ui.select
  local ok, picker = pcall(require, 'snacks.picker')
  if ok and picker then
    local items = {}
    for i, term in ipairs(term_bufs) do
      local display = string.format("%d: %s (pid: %s)", i, vim.fn.fnamemodify(term.name, ":t"), term.pid or "?")
      table.insert(items, {
        text = display,
        buf = term.buf,
        idx = i,
      })
    end

    picker.select(items, {
      prompt = "Select Terminal",
      format_item = function(item) return item.text end,
    }, function(choice)
      if choice then
        -- Find or create window for the terminal
        local wins = vim.fn.win_findbuf(choice.buf)
        if #wins > 0 then
          vim.api.nvim_set_current_win(wins[1])
        else
          vim.cmd('botright split')
          vim.api.nvim_set_current_buf(choice.buf)
        end
        vim.cmd('startinsert')
      end
    end)
  else
    -- Fallback to vim.ui.select
    local items = {}
    local buf_map = {}
    for i, term in ipairs(term_bufs) do
      local display = string.format("%d: %s (pid: %s)", i, vim.fn.fnamemodify(term.name, ":t"), term.pid or "?")
      table.insert(items, display)
      buf_map[display] = term.buf
    end

    vim.ui.select(items, {
      prompt = "Select Terminal:",
    }, function(choice)
      if choice then
        local buf = buf_map[choice]
        local wins = vim.fn.win_findbuf(buf)
        if #wins > 0 then
          vim.api.nvim_set_current_win(wins[1])
        else
          vim.cmd('botright split')
          vim.api.nvim_set_current_buf(buf)
        end
        vim.cmd('startinsert')
      end
    end)
  end
end

--- Send text to a terminal
--- @param text string Text to send
--- @param term_buf number|nil Terminal buffer (uses first terminal if nil)
local function term_send(text, term_buf)
  local term_bufs = get_terminal_buffers()
  if #term_bufs == 0 then
    vim.notify("No terminals open", vim.log.levels.WARN)
    return
  end

  local buf = term_buf or term_bufs[1].buf
  local job_id = vim.b[buf].terminal_job_id
  if job_id then
    vim.fn.chansend(job_id, text .. "\n")
  end
end

--- Change current buffer to vertical split
local function change_to_vsplit()
  local buf = vim.api.nvim_get_current_buf()
  vim.cmd('close')
  vim.cmd('vsplit')
  vim.api.nvim_set_current_buf(buf)
end

--- Change current buffer to horizontal split
local function change_to_hsplit()
  local buf = vim.api.nvim_get_current_buf()
  vim.cmd('close')
  vim.cmd('split')
  vim.api.nvim_set_current_buf(buf)
end

-- ============================================================================
-- User Commands
-- ============================================================================

-- :TermNew [pos=position] [name=name] - Open new terminal
vim.api.nvim_create_user_command('TermNew', function(cmd_opts)
  local position = "bottom"
  local name = nil
  -- Parse named arguments like pos=float name=somename
  for _, arg in ipairs(cmd_opts.fargs) do
    local key, value = arg:match("^(%w+)=(.+)$")
    if key and value then
      if key == "pos" or key == "position" then
        position = value
      elseif key == "name" then
        name = value
      end
    elseif not arg:match("=") then
      -- Fallback: treat bare argument as position for backward compat
      position = arg
    end
  end
  term_new({ position = position, name = name })
end, {
  nargs = '*',
  complete = function(_, cmdline)
    local args = vim.split(cmdline, '%s+')
    local last = args[#args] or ""
    if last:match("^pos=") then
      return { 'pos=bottom', 'pos=right', 'pos=left', 'pos=top', 'pos=float' }
    elseif last:match("^name=") then
      return {}
    else
      return { 'pos=', 'name=' }
    end
  end,
  desc = 'Open new terminal. Usage: :TermNew [pos=position] [name=name]'
})

-- :TermSelect - Pick from open terminals
vim.api.nvim_create_user_command('TermSelect', function()
  term_select()
end, {
  desc = 'Select from open terminals'
})

-- :TermToggle [num] [position] - Toggle numbered terminal (like ToggleTerm)
vim.api.nvim_create_user_command('TermToggle', function(cmd_opts)
  local num = tonumber(cmd_opts.fargs[1]) or 1
  local position = cmd_opts.fargs[2] or "bottom"
  toggle_terminal(num, position)
end, {
  nargs = '*',
  complete = function(_, cmdline)
    local args = vim.split(cmdline, '%s+')
    if #args <= 2 then
      return { '1', '2', '3', '4', '5', '6', '7', '8', '9' }
    else
      return { 'bottom', 'right', 'left', 'top', 'float' }
    end
  end,
  desc = 'Toggle numbered terminal. Usage: :TermToggle [num] [position]'
})

-- :TermSend [text] - Send text to terminal
vim.api.nvim_create_user_command('TermSend', function(cmd_opts)
  term_send(cmd_opts.args)
end, {
  nargs = '+',
  desc = 'Send text to terminal'
})

-- :TermList - List all terminals
vim.api.nvim_create_user_command('TermList', function()
  local term_bufs = get_terminal_buffers()
  if #term_bufs == 0 then
    vim.notify("No terminals open", vim.log.levels.INFO)
    return
  end
  for i, term in ipairs(term_bufs) do
    print(string.format("%d: buf=%d pid=%s %s", i, term.buf, term.pid or "?", vim.fn.fnamemodify(term.name, ":t")))
  end
end, {
  desc = 'List all open terminals'
})

-- :Cvsplit - Change current buffer to vertical split
vim.api.nvim_create_user_command('Cvsplit', change_to_vsplit, {
  desc = 'Change current buffer to vertical split'
})

-- :Chsplit - Change current buffer to horizontal split
vim.api.nvim_create_user_command('Chsplit', change_to_hsplit, {
  desc = 'Change current buffer to horizontal split'
})

--show kepbindings with whichkey
--add your own here if you want them to
--show up in the popup as well

-- normal mode
wk.add({
  { '<c-LeftMouse>', '<cmd>lua vim.lsp.buf.definition()<CR>', desc = 'go to definition' },
  { '<c-q>', '<cmd>q<cr>', desc = 'close buffer' },
  { '<esc>', '<cmd>noh<cr>', desc = 'remove search highlight' },
  { 'gf', ':e <cfile><CR>', desc = 'edit file' },
  { '<C-M-i>', insert_py_chunk, desc = 'python code chunk' },
  { '<m-I>', insert_py_chunk, desc = 'python code chunk' },
  { ']q', ':silent cnext<cr>', desc = '[q]uickfix next' },
  { '[q', ':silent cprev<cr>', desc = '[q]uickfix prev' },
  { 'z?', ':setlocal spell!<cr>', desc = 'toggle [z]pellcheck' },
  { 'zl', ':Telescope spell_suggest<cr>', desc = '[l]ist spelling suggestions' },
}, { mode = 'n', silent = true })

-- visual mode
wk.add({
  { '<M-j>', "ddp", desc = 'move line down' },
  { '<M-k>', "ddkkp", desc = 'move line up' },
  { '.', ':norm .<cr>', desc = 'repeat last normal mode command' },
  { '<C-q>', ':norm @q<cr>', desc = 'repeat q macro' },
}, { mode = 'v' })

-- visual with <leader>
wk.add {
  { '<leader>p', '"_dP', desc = 'replace without overwriting reg', mode = 'v' },
  { '<leader>d', '"_d', desc = 'delete without overwriting reg', mode = 'v' },
}

-- insert mode
wk.add {
  { '<m-->', ' <- ', desc = 'assign', mode = 'i' },
  { '<m-m>', ' |>', desc = 'pipe', mode = 'i' },
  { '<C-M-i>', insert_py_chunk, desc = 'python code chunk', mode = 'i' },
  { '<m-I>', insert_py_chunk, desc = 'python code chunk', mode = 'i' },
  { '<c-x><c-x>', '<c-x><c-o>', desc = 'omnifunc completion', mode = 'i' },
}

local function new_terminal_python()
  new_terminal 'uv run python'
end


local function new_terminal_ipython()
  new_terminal 'uv tool run ipython --no-confirm-exit'
end


-- normal mode with <leader>
wk.add({
  { '<leader>c', group = '[c]ode / [c]ell / [c]hunk' },
  { '<leader>cp', new_terminal_python, desc = 'new [p]ython terminal' },
  { '<leader>ci', new_terminal_ipython, desc = 'new [i]python terminal' },
  { '<leader>e', group = '[e]dit' },
  { '<leader>d', group = '[d]ebug' },
  { '<leader>dt', group = '[t]est' },
  { '<leader>f', group = '[f]ind (snacks)' },
  { '<leader>s', group = '[s]earch' },
  { '<leader>m', group = '[m]isc' },
  { '<leader>b', group = '[b]uffer' },
  { '<leader>ff', function() require('misc.pickers').find_files() end, desc = '[f]iles' },
  { '<leader>fh', function() require('misc.pickers').help_tags() end, desc = '[h]elp' },
  { '<leader>fk', function() require('misc.pickers').keymaps() end, desc = '[k]eymaps' },
  { '<leader>fg', function() require('misc.pickers').live_grep() end, desc = '[g]rep' },
  { '<leader>fb', function() require('misc.pickers').current_buffer_fuzzy_find() end, desc = '[b]uffer fuzzy find' },
  { '<leader>fm', function() require('misc.pickers').marks() end, desc = '[m]arks' },
  { '<leader>fM', function() require('misc.pickers').man_pages() end, desc = '[M]an pages' },
  { '<leader>fc', function() require('misc.pickers').git_commits() end, desc = 'git [c]ommits' },
  { '<leader>f<space>', function() require('misc.pickers').buffers() end, desc = '[ ] buffers' },
  { '<leader>fd', function() require('misc.pickers').buffers() end, desc = '[d] buffers' },
  { '<leader>fq', function() require('misc.pickers').quickfix() end, desc = '[q]uickfix' },
  { '<leader>fl', function() require('misc.pickers').loclist() end, desc = '[l]oclist' },
  { '<leader>fj', function() require('misc.pickers').jumplist() end, desc = '[j]umplist' },

  -- Snacks-enhanced pickers (use Snacks if available, else fall back)
  { '<leader>su', function()
      local ok,s = pcall(require, 'snacks.picker')
      if ok and s and s.undo then pcall(s.undo) else vim.notify('Undo picker not available', vim.log.levels.WARN) end
    end, desc = 'Undo history' },
  { '<leader>sd', function()
      local ok,s = pcall(require, 'snacks.picker')
      if ok and s and s.diagnostics then pcall(s.diagnostics) else
        local ok2, tb = pcall(require, 'telescope.builtin')
        if ok2 and tb and tb.diagnostics then tb.diagnostics() else vim.diagnostic.setqflist({ open = true }) end
      end
    end, desc = 'Diagnostics' },
  { '<leader>s/', function()
      local ok,s = pcall(require, 'snacks.picker')
      if ok and s and s.search_history then pcall(s.search_history) else vim.notify('Search history not available', vim.log.levels.WARN) end
    end, desc = 'Search History' },
  { '<leader>sB', function()
      local ok,s = pcall(require, 'snacks.picker')
      if ok and s and s.grep_buffers then pcall(s.grep_buffers) else require('misc.pickers').current_buffer_fuzzy_find() end
    end, desc = 'Grep Open Buffers' },
  { '<leader>sw', function()
      local ok,s = pcall(require, 'snacks.picker')
      if ok and s and s.grep_word then pcall(s.grep_word) else require('misc.pickers').live_grep() end
    end, desc = 'Grep word/selection', mode = { 'n', 'x' } },

  { '<leader>g', group = '[g]it' },
  { '<leader>gc', ':GitConflictRefresh<cr>', desc = '[c]onflict' },
  -- { '<leader>gs', ':Gitsigns<cr>', desc = 'git [s]igns' },
  { '<leader>gm', function() require('misc.ai-commit').commit() end, desc = 'AI commit [m]essage' },
  { '<leader>gM', function() require('misc.ai-commit').select_model() end, desc = 'Set AI [M]odel' },
  -- lazygit keymaps are in snacks.lua: <leader>gg, <leader>gf, <leader>gl
  { '<leader>td', function()
      require('trouble').open('workspace_diagnostics')
    end, desc = 'Trouble: Workspace Diagnostics' },
  { '<leader>gwc', ":lua require('telescope').extensions.git_worktree.create_git_worktree()<cr>", desc = 'worktree create' },
  { '<leader>gws', ":lua require('telescope').extensions.git_worktree.git_worktrees()<cr>", desc = 'worktree switch' },
  { '<leader>gd', group = '[d]iff' },
  { '<leader>gdo', ':DiffviewOpen<cr>', desc = '[o]pen' },
  { '<leader>gdc', ':DiffviewClose<cr>', desc = '[c]lose' },
  { '<leader>gdf', ':DiffviewFileHistory %<cr>', desc = '[f]ile history (current)' },
  { '<leader>gdh', ':DiffviewFileHistory<cr>', desc = '[h]istory (all files)' },
  { '<leader>gds', ':DiffviewOpen --staged<cr>', desc = '[s]taged changes' },
  { '<leader>gb', group = '[b]lame' },
  { '<leader>gbb', ':GitBlameToggle<cr>', desc = '[b]lame toggle virtual text' },
  { '<leader>gbo', ':GitBlameOpenCommitURL<cr>', desc = '[o]pen' },
  { '<leader>gbc', ':GitBlameCopyCommitURL<cr>', desc = '[c]opy' },
  { '<leader>h', group = '[h]elp / [h]ide / debug' },
  { '<leader>hc', group = '[c]onceal' },
  { '<leader>hch', ':set conceallevel=1<cr>', desc = '[h]ide/conceal' },
  { '<leader>hcs', ':set conceallevel=0<cr>', desc = '[s]how/unconceal' },
  { '<leader>ht', group = '[t]reesitter' },
  { '<leader>htt', vim.treesitter.inspect_tree, desc = 'show [t]ree' },
  { '<leader>i', group = '[i]mage' },
  { '<leader>l', group = '[l]anguage/lsp' },
  { '<leader>lr', vim.lsp.buf.references, desc = '[r]eferences' },
  { '<leader>lR', vim.lsp.buf.rename, desc = '[R]ename' },
  { '<leader>lD', vim.lsp.buf.type_definition, desc = 'type [D]efinition' },
  { '<leader>la', vim.lsp.buf.code_action, desc = 'code [a]ction' },
  { '<leader>le', vim.diagnostic.open_float, desc = 'diagnostics (show hover [e]rror)' },
  { '<leader>ld', group = '[d]iagnostics' },
  {
    '<leader>ldd',
    function()
      vim.diagnostic.enable(false)
    end,
    desc = '[d]isable',
  },
  { '<leader>lde', vim.diagnostic.enable, desc = '[e]nable' },
  { '<leader>ss', function()
      local ok,s = pcall(require, 'snacks.picker')
      if ok and s and s.lsp_symbols then pcall(s.lsp_symbols) else vim.lsp.buf.document_symbol() end
    end, desc = 'LSP Symbols' },
  { '<leader>sS', function()
      local ok,s = pcall(require, 'snacks.picker')
      if ok and s and s.lsp_workspace_symbols then pcall(s.lsp_workspace_symbols) else vim.lsp.buf.workspace_symbol() end
    end, desc = 'LSP Workspace Symbols' },
  { '<leader>v', group = '[v]im' },
  { '<leader>vl', ':Lazy<cr>', desc = '[l]azy package manager' },
  { '<leader>vm', ':Mason<cr>', desc = '[m]ason software installer' },
  { '<leader>vr', group = '[R]esession' },
  { '<leader>vs', ':e $MYVIMRC | :cd %:p:h | split . | wincmd k<cr>', desc = '[s]ettings, edit vimrc' },
  { '<leader>vh', ':execute "h " . expand("<cword>")<cr>', desc = 'vim [h]elp for current word' },
  { '<leader>w', group = '[W]orkspace' },
  { '<leader>x', group = 'e[x]ecute' },
  { '<leader>xx', ':w<cr>:source %<cr>', desc = '[x] source %' },
  { '<leader>a', group = '[A]i tools' },
  { '<leader>st', ':Store<cr>', desc = 'Open Store' },
  { '<leader>t', group = '[t]erminal' },
  { '<leader>tn', function() term_new({ position = 'bottom' }) end, desc = '[n]ew terminal (bottom)' },
  { '<leader>tv', function() term_new({ position = 'right' }) end, desc = 'new terminal [v]ertical (right)' },
  { '<leader>tf', function() term_new({ position = 'float' }) end, desc = 'new terminal [f]loat' },
  { '<leader>ts', term_select, desc = '[s]elect terminal' },
  { '<leader>tl', ':TermList<cr>', desc = '[l]ist terminals' },
  { '<leader>t1', function() toggle_terminal(1) end, desc = 'toggle terminal [1]' },
  { '<leader>t2', function() toggle_terminal(2) end, desc = 'toggle terminal [2]' },
  { '<leader>t3', function() toggle_terminal(3) end, desc = 'toggle terminal [3]' },
  { '<leader>wv', change_to_vsplit, desc = 'change to [v]ertical split' },
  { '<leader>wh', change_to_hsplit, desc = 'change to [h]orizontal split' },
}, { mode = 'n' })
