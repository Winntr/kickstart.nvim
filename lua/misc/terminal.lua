local function extract_terminal_path(line_text)
  -- Match Next.js-style paths like ./path/file.tsx:12:4, Windows paths, and plain relative paths.
  local patterns = {
    '([%a]:\\[^:%s]+%.[%w]+)%:?(%d*)%:?(%d*)',
    '(%./[^:%s]+%.[%w]+)%:?(%d*)%:?(%d*)',
    '(%.[/\\][^:%s]+%.[%w]+)%:?(%d*)%:?(%d*)',
    '([%w%._%-%/%\\%(%)~]+%.[%w]+)%:?(%d*)%:?(%d*)',
  }

  for _, pattern in ipairs(patterns) do
    local path_part, line_num, col_num = line_text:match(pattern)
    if path_part then
      return path_part, line_num, col_num
    end
  end
end

local function resolve_target_file(path)
  local cwd = vim.loop.cwd() or vim.fn.getcwd()
  local home = vim.fn.expand '$HOME'

  local function readable(candidate)
    return candidate and candidate ~= '' and vim.fn.filereadable(candidate) == 1
  end

  local function normalize(candidate)
    return vim.fs.normalize(candidate)
  end

  local candidates = {
    path,
    normalize(path),
    vim.fs.joinpath(cwd, path),
    normalize(vim.fs.joinpath(cwd, path)),
  }

  if path:sub(1, 2) == './' or path:sub(1, 2) == '.\\' then
    local rel_path = path:sub(3)
    table.insert(candidates, vim.fs.joinpath(cwd, rel_path))
    table.insert(candidates, normalize(vim.fs.joinpath(cwd, rel_path)))
  end

  if home ~= '' then
    local stripped = path:gsub('^%.[/\\]', ''):gsub('^[/\\]', '')
    table.insert(candidates, vim.fs.joinpath(home, stripped))
    table.insert(candidates, normalize(vim.fs.joinpath(home, stripped)))
  end

  for _, candidate in ipairs(candidates) do
    if readable(candidate) then
      return candidate
    end
  end
end

local function jump_to_path_under_cursor()
  local line_text = vim.api.nvim_get_current_line()
  local path_part, line_num, col_num = extract_terminal_path(line_text)

  if not path_part then
    print 'No path structure found on this line.'
    return
  end

  local target_file = resolve_target_file(path_part)

  if target_file then
    vim.cmd 'wincmd p'
    vim.cmd('edit ' .. vim.fn.fnameescape(target_file))

    if line_num and line_num ~= '' then
      vim.api.nvim_win_set_cursor(0, { tonumber(line_num), tonumber(col_num) or 0 })
    end
  else
    print('Could not locate file on disk: ' .. path_part)
  end
end

local function attach_terminal_path_jumping(bufnr)
  if vim.bo[bufnr].buftype ~= 'terminal' then
    return
  end

  local opts = { buffer = bufnr, silent = true, noremap = true, desc = 'Robust terminal path jumping' }

  vim.keymap.set('n', 'gf', jump_to_path_under_cursor, opts)
  vim.keymap.set('t', 'gf', function()
    vim.cmd 'stopinsert'
    jump_to_path_under_cursor()
  end, opts)
end

vim.api.nvim_create_autocmd({ 'TermOpen', 'TermEnter', 'BufEnter' }, {
  group = vim.api.nvim_create_augroup('TerminalGoToFile', { clear = true }),
  callback = function(args)
    attach_terminal_path_jumping(args.buf)
  end,
})

for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
  if vim.bo[bufnr].buftype == 'terminal' then
    attach_terminal_path_jumping(bufnr)
  end
end
