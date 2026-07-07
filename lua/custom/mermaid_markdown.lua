--- Preview / render ```mermaid fences inside markdown buffers.
---
--- @class MermaidMarkdownConfig
--- @field preview_key string
--- @field render_key string

local M = {}

--- @type MermaidMarkdownConfig
local cfg = {
  preview_key = '<leader>um',
  render_key = '<leader>uM',
}

local MERMAID_QUERY = vim.treesitter.query.parse('markdown', [[
  (fenced_code_block
    (info_string (language) @lang)
    (code_fence_content) @content)
  (#eq? @lang "mermaid")
]])

local CONTENT_CAPTURE do
  for i, name in ipairs(MERMAID_QUERY.captures) do
    if name == 'content' then
      CONTENT_CAPTURE = i
      break
    end
  end
end
assert(CONTENT_CAPTURE, 'mermaid markdown query missing @content capture')

--- @param buf integer
--- @param row? integer 0-indexed
--- @return TSNode|nil content_node
--- @return TSNode|nil block_node
local function mermaid_block_at(buf, row)
  row = row or (vim.api.nvim_win_get_cursor(0)[1] - 1)
  if vim.bo[buf].filetype ~= 'markdown' and vim.bo[buf].filetype ~= 'Avante' then
    return nil, nil
  end

  local ok, parser = pcall(vim.treesitter.get_parser, buf, 'markdown')
  if not ok or not parser then
    return nil, nil
  end

  parser:parse(true)
  local trees = parser:trees()
  local root = trees[1] and trees[1]:root()
  if not root then
    return nil, nil
  end

  for _, match in MERMAID_QUERY:iter_matches(root, buf, 0, -1, { all = true }) do
    local captures = match[CONTENT_CAPTURE]
    local content = captures and captures[1]
    if content then
      local block = content:parent()
      while block and block:type() ~= 'fenced_code_block' do
        block = block:parent()
      end
      if block then
        local s, _, e, _ = block:range()
        if row >= s and row <= e then
          return content, block
        end
      end
    end
  end

  return nil, nil
end

--- @param content_node TSNode
--- @param buf integer
--- @return string[]
local function node_lines(content_node, buf)
  local s, _, e, _ = content_node:range()
  return vim.api.nvim_buf_get_lines(buf, s, e + 1, false)
end

--- @param lines string[]
--- @param fn fun(scratch: integer)
local function with_scratch(lines, fn)
  local scratch = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(scratch, 0, -1, false, lines)
  vim.bo[scratch].filetype = 'mermaid'
  vim.bo[scratch].buftype = 'acwrite'
  vim.bo[scratch].bufhidden = 'wipe'
  vim.cmd('noautocmd setlocal nomodified')
  fn(scratch)
end

--- @param buf? integer
function M.preview_at_cursor(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  local content, _ = mermaid_block_at(buf)
  if not content then
    vim.notify('No ```mermaid block at cursor', vim.log.levels.WARN)
    return
  end

  local lines = node_lines(content, buf)
  if #lines == 0 or (#lines == 1 and lines[1] == '') then
    vim.notify('Mermaid block is empty', vim.log.levels.WARN)
    return
  end

  with_scratch(lines, function(scratch)
    vim.api.nvim_buf_call(scratch, function()
      require('mermaid.preview').preview()
    end)
  end)
end

--- @param buf? integer
function M.render_at_cursor(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  local content, _ = mermaid_block_at(buf)
  if not content then
    vim.notify('No ```mermaid block at cursor', vim.log.levels.WARN)
    return
  end

  local lines = node_lines(content, buf)
  with_scratch(lines, function(scratch)
    vim.api.nvim_buf_call(scratch, function()
      local ok, render = pcall(require, 'mermaid.render')
      if not ok then
        vim.notify('mermaid.nvim render module not available', vim.log.levels.ERROR)
        return
      end
      render.render()
    end)
  end)
end

--- @param opts? MermaidMarkdownConfig
function M.setup(opts)
  if opts then
    cfg = vim.tbl_extend('force', cfg, opts)
  end

  local function map_markdown(buf)
    vim.keymap.set('n', cfg.preview_key, M.preview_at_cursor, {
      buffer = buf,
      desc = 'Mermaid preview (block at cursor)',
      silent = true,
    })
    vim.keymap.set('n', cfg.render_key, M.render_at_cursor, {
      buffer = buf,
      desc = 'Mermaid render inline (block at cursor)',
      silent = true,
    })
  end

  vim.api.nvim_create_autocmd('FileType', {
    pattern = { 'markdown', 'Avante' },
    callback = function(args)
      map_markdown(args.buf)
    end,
  })

  vim.api.nvim_create_user_command('MermaidBlockPreview', function()
    M.preview_at_cursor()
  end, { desc = 'Live browser preview for mermaid fence at cursor' })

  vim.api.nvim_create_user_command('MermaidBlockRender', function()
    M.render_at_cursor()
  end, { desc = 'Inline terminal render for mermaid fence at cursor' })
end

-- ponytail: self-check — query parses
do
  assert(MERMAID_QUERY ~= nil)
end

return M
