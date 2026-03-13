local function set_terminal_keymaps()
  local opts = { buffer = 0 }
  local bufname = vim.api.nvim_buf_get_name(0)

  -- Don't override <Esc> for lazygit (it needs escape for navigation)
  if not bufname:match('lazygit') then
    vim.keymap.set('t', '<esc>', [[<C-\><C-n>]], opts)
  end

  vim.keymap.set('t', '<C-h>', [[<Cmd>wincmd h<CR>]], opts)
  vim.keymap.set('t', '<C-j>', [[<Cmd>wincmd j<CR>]], opts)
  vim.keymap.set('t', '<C-k>', [[<Cmd>wincmd k<CR>]], opts)
  vim.keymap.set('t', '<C-l>', [[<Cmd>wincmd l<CR>]], opts)
end

-- ============================================================================
-- Terminal Mode Visual Indicator
-- ============================================================================

-- Define highlight groups for terminal modes
vim.api.nvim_set_hl(0, 'TerminalNormalMode', { bg = '#2d1f1f' })  -- Reddish tint for normal mode
vim.api.nvim_set_hl(0, 'TerminalInsertMode', { bg = 'NONE' })     -- Default for insert mode
vim.api.nvim_set_hl(0, 'TerminalModeIndicator', { fg = '#ff6b6b', bg = '#2d1f1f', bold = true })

-- Track the floating window for mode indicator
local term_mode_indicator_win = nil
local term_mode_indicator_buf = nil

--- Show floating mode indicator in terminal window
local function show_term_mode_indicator()
  -- Close existing indicator if any
  if term_mode_indicator_win and vim.api.nvim_win_is_valid(term_mode_indicator_win) then
    vim.api.nvim_win_close(term_mode_indicator_win, true)
  end

  -- Create buffer for indicator - compact "N" badge
  term_mode_indicator_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(term_mode_indicator_buf, 0, -1, false, { 'N' })

  -- Get current window dimensions
  local win_width = vim.api.nvim_win_get_width(0)

  -- Create small floating window in top-right corner (no border for compactness)
  term_mode_indicator_win = vim.api.nvim_open_win(term_mode_indicator_buf, false, {
    relative = 'win',
    win = 0,
    width = 1,
    height = 1,
    row = 0,
    col = win_width - 2,
    style = 'minimal',
    border = 'none',
    focusable = false,
    zindex = 100,
  })

  -- Set highlight
  vim.api.nvim_win_set_option(term_mode_indicator_win, 'winhl', 'Normal:TerminalModeIndicator')
end

--- Hide the mode indicator
local function hide_term_mode_indicator()
  if term_mode_indicator_win and vim.api.nvim_win_is_valid(term_mode_indicator_win) then
    vim.api.nvim_win_close(term_mode_indicator_win, true)
    term_mode_indicator_win = nil
  end
end

--- Update terminal visual based on mode
local function update_terminal_mode_visual()
  local mode = vim.api.nvim_get_mode().mode
  local buftype = vim.bo.buftype

  if buftype ~= 'terminal' then
    hide_term_mode_indicator()
    return
  end

  if mode == 't' then
    -- Terminal insert mode - hide indicator, normal background
    hide_term_mode_indicator()
    vim.wo.winhighlight = ''
  else
    -- Terminal normal mode - show indicator, tinted background
    show_term_mode_indicator()
    vim.wo.winhighlight = 'Normal:TerminalNormalMode'
  end
end

-- Autocommands for terminal mode changes
-- Only fire for terminal-related mode transitions (t = terminal mode)
-- This prevents the expensive floating window operations from running on every keypress
vim.api.nvim_create_autocmd('ModeChanged', {
  pattern = { '*:t', 't:*' },  -- Only when entering or leaving terminal mode
  callback = function()
    -- Small delay to ensure mode has fully changed
    vim.schedule(update_terminal_mode_visual)
  end,
  desc = 'Update terminal mode visual indicator',
})

vim.api.nvim_create_autocmd('BufEnter', {
  pattern = 'term://*',
  callback = function()
    vim.schedule(update_terminal_mode_visual)
  end,
  desc = 'Update terminal mode visual on buffer enter',
})

vim.api.nvim_create_autocmd('BufLeave', {
  pattern = 'term://*',
  callback = function()
    hide_term_mode_indicator()
  end,
  desc = 'Hide terminal mode indicator on buffer leave',
})

-- ============================================================================

-- Only check for external file changes on FocusGained (not BufEnter - too frequent)
vim.api.nvim_create_autocmd({ 'FocusGained' }, {
  pattern = { '*' },
  command = 'checktime',
})

vim.api.nvim_create_autocmd({ 'TermOpen' }, {
  pattern = { '*' },
  callback = function(_)
    vim.cmd.setlocal 'nonumber'
    vim.wo.signcolumn = 'no'
    set_terminal_keymaps()
  end,
})

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.highlight.on_yank()`
-- vim.api.nvim_create_autocmd('TextYankPost', {
--   desc = 'Highlight when yanking (copying) text',
--   group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
--   callback = function()
--     vim.highlight.on_yank()
--   end,
-- })

-- ============================================================================
-- Prevent Terminal from Filling Screen
-- ============================================================================
-- DISABLED: Causes issues with Oil.nvim - opens empty buffers instead of Oil view

-- -- Helper: Count non-terminal listed buffers
-- local function count_real_buffers()
--   local count = 0
--   for _, buf in ipairs(vim.api.nvim_list_bufs()) do
--     if vim.api.nvim_buf_is_valid(buf)
--       and vim.bo[buf].buflisted
--       and vim.bo[buf].buftype ~= 'terminal'
--     then
--       count = count + 1
--     end
--   end
--   return count
-- end

-- -- Handle :q (quit) - fires before window closes
-- vim.api.nvim_create_autocmd('QuitPre', {
--   callback = function()
--     if vim.bo.buftype == 'terminal' then return end
--     if count_real_buffers() <= 1 then
--       vim.cmd('enew')
--     end
--   end,
--   desc = 'Prevent terminal from filling screen on :q',
-- })

-- -- Handle :bd (buffer delete)
-- vim.api.nvim_create_autocmd('BufDelete', {
--   callback = function(args)
--     if vim.bo[args.buf].buftype == 'terminal' then return end
--     if count_real_buffers() <= 1 then
--       -- Schedule to run after the current command completes
--       vim.schedule(function()
--         vim.cmd('enew')
--       end)
--     end
--   end,
--   desc = 'Prevent terminal from filling screen on :bd',
-- })
