local function set_terminal_keymaps()
  local opts = { buffer = 0 }
  local bufname = vim.api.nvim_buf_get_name(0)

  -- Don't override <Esc> for lazygit (it needs escape for navigation)
  if not bufname:match 'lazygit' then
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

-- Light red WinSeparator when terminal is inactive (normal mode or unfocused).
-- With globalstatus enabled, the separator above a bottom terminal is owned by
-- the window(s) above it, not the terminal window itself.
vim.api.nvim_set_hl(0, 'TerminalInactiveBorder', { fg = '#ff6b6b' })

local separator_owner_state = {}
local inactive_terminal_owners = {}

local function is_terminal_window(win)
  if not win or not vim.api.nvim_win_is_valid(win) then
    return false
  end

  local buf = vim.api.nvim_win_get_buf(win)
  return vim.bo[buf].buftype == 'terminal'
end

local function strip_winhighlight_group(winhighlight, group)
  if winhighlight == '' then
    return ''
  end

  local filtered = {}
  for _, item in ipairs(vim.split(winhighlight, ',', { trimempty = true })) do
    if not item:match('^' .. group .. ':') then
      table.insert(filtered, item)
    end
  end

  return table.concat(filtered, ',')
end

local function with_winhighlight_group(winhighlight, mapping)
  local cleaned = strip_winhighlight_group(winhighlight, 'WinSeparator')
  if cleaned == '' then
    return mapping
  end

  return cleaned .. ',' .. mapping
end

local function get_terminal_separator_owners(term_win)
  if not is_terminal_window(term_win) then
    return {}
  end

  local term_pos = vim.api.nvim_win_get_position(term_win)
  local term_row = term_pos[1]
  local term_col = term_pos[2]
  local term_left = term_col
  local term_right = term_col + vim.api.nvim_win_get_width(term_win) - 1
  local term_tab = vim.api.nvim_win_get_tabpage(term_win)
  local owners = {}

  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(term_tab)) do
    if win ~= term_win and vim.api.nvim_win_is_valid(win) then
      local pos = vim.api.nvim_win_get_position(win)
      local separator_row = pos[1] + vim.api.nvim_win_get_height(win)
      local win_left = pos[2]
      local win_right = pos[2] + vim.api.nvim_win_get_width(win) - 1
      local overlaps_terminal = win_left <= term_right and win_right >= term_left

      if separator_row == term_row - 1 and overlaps_terminal then
        table.insert(owners, win)
      end
    end
  end

  return owners
end

local function claim_separator(owner_win)
  local current = vim.api.nvim_get_option_value('winhighlight', { win = owner_win })
  local state = separator_owner_state[owner_win]

  if not state then
    state = { count = 0, original = current }
    separator_owner_state[owner_win] = state
  end

  state.count = state.count + 1

  vim.api.nvim_set_option_value(
    'winhighlight',
    with_winhighlight_group(current, 'WinSeparator:TerminalInactiveBorder'),
    { win = owner_win }
  )
end

local function release_separator(owner_win)
  local state = separator_owner_state[owner_win]
  if not state then
    return
  end

  state.count = state.count - 1
  if state.count > 0 then
    return
  end

  separator_owner_state[owner_win] = nil
  if vim.api.nvim_win_is_valid(owner_win) then
    vim.api.nvim_set_option_value('winhighlight', state.original, { win = owner_win })
  end
end

local function clear_term_inactive(term_win)
  local owners = inactive_terminal_owners[term_win]
  if not owners then
    return
  end

  inactive_terminal_owners[term_win] = nil

  for owner_win, _ in pairs(owners) do
    release_separator(owner_win)
  end
end

local function set_term_inactive(term_win)
  clear_term_inactive(term_win)

  local owners = get_terminal_separator_owners(term_win)
  if #owners == 0 then
    return
  end

  local claimed = {}
  for _, owner_win in ipairs(owners) do
    claim_separator(owner_win)
    claimed[owner_win] = true
  end

  inactive_terminal_owners[term_win] = claimed
end

local function sync_visible_terminals()
  local current_tab = vim.api.nvim_get_current_tabpage()
  local current_win = vim.api.nvim_get_current_win()

  for term_win, _ in pairs(inactive_terminal_owners) do
    if not vim.api.nvim_win_is_valid(term_win) then
      clear_term_inactive(term_win)
    elseif vim.api.nvim_win_get_tabpage(term_win) == current_tab then
      set_term_inactive(term_win)
    end
  end

  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(current_tab)) do
    if is_terminal_window(win) and win ~= current_win then
      set_term_inactive(win)
    end
  end
end

local term_indicator_group = vim.api.nvim_create_augroup('TerminalBorderIndicator', { clear = true })

vim.api.nvim_create_autocmd('TermOpen', {
  group = term_indicator_group,
  callback = function()
    set_terminal_keymaps()
    set_term_inactive(vim.api.nvim_get_current_win())
  end,
})

vim.api.nvim_create_autocmd('TermEnter', {
  group = term_indicator_group,
  callback = function()
    local win = vim.api.nvim_get_current_win()
    clear_term_inactive(win)
    sync_visible_terminals()
  end,
})

vim.api.nvim_create_autocmd('TermLeave', {
  group = term_indicator_group,
  callback = function()
    set_term_inactive(vim.api.nvim_get_current_win())
  end,
})

vim.api.nvim_create_autocmd('WinLeave', {
  group = term_indicator_group,
  callback = function()
    local win = vim.api.nvim_get_current_win()
    if is_terminal_window(win) then
      set_term_inactive(win)
    else
      sync_visible_terminals()
    end
  end,
})

vim.api.nvim_create_autocmd('WinEnter', {
  group = term_indicator_group,
  callback = function()
    local win = vim.api.nvim_get_current_win()
    if is_terminal_window(win) then
      if vim.api.nvim_get_mode().mode == 't' then
        clear_term_inactive(win)
      else
        set_term_inactive(win)
      end
    end

    sync_visible_terminals()
  end,
})

vim.api.nvim_create_autocmd({ 'WinClosed', 'TabEnter', 'VimResized' }, {
  group = term_indicator_group,
  callback = function()
    sync_visible_terminals()
  end,
})
