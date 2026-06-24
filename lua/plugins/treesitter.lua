local PARSERS = {
  'python',
  'markdown',
  'markdown_inline',
  'bash',
  'yaml',
  'lua',
  'vim',
  'query',
  'vimdoc',
  'html',
  'css',
  'dot',
  'angular',
  'javascript',
  'mermaid',
  'typescript',
  'http',
  'json',
  'sql',
}

local function install_missing_parsers()
  local ok_cfg, cfg = pcall(require, 'nvim-treesitter.config')
  if not ok_cfg then
    return
  end
  local installed = cfg.get_installed()
  local to_install = vim.iter(PARSERS)
    :filter(function(parser)
      return not vim.tbl_contains(installed, parser)
    end)
    :totable()
  if #to_install > 0 then
    require('nvim-treesitter').install(to_install)
  end
end

local function setup_highlight_and_indent()
  vim.api.nvim_create_autocmd('FileType', {
    callback = function()
      pcall(vim.treesitter.start)
      pcall(function()
        vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end)
    end,
  })
end

local function setup_incremental_selection()
  vim.keymap.set('n', 'gnn', function()
    pcall(vim.treesitter.select, { direction = 'parent', count = 1 })
  end, { desc = 'Init treesitter selection' })

  vim.keymap.set('x', 'grn', function()
    pcall(vim.treesitter.select, { direction = 'parent', count = vim.v.count1 })
  end, { desc = 'Expand treesitter selection' })

  vim.keymap.set('x', 'grc', function()
    pcall(vim.treesitter.select, { direction = 'parent', count = vim.v.count1 })
  end, { desc = 'Expand treesitter selection to scope' })

  vim.keymap.set('x', 'grm', function()
    pcall(vim.treesitter.select, { direction = 'child', count = vim.v.count1 })
  end, { desc = 'Shrink treesitter selection' })
end

local function setup_textobjects()
  require('nvim-treesitter-textobjects').setup {
    select = {
      lookahead = true,
    },
    move = {
      set_jumps = true,
    },
  }

  local select = require('nvim-treesitter-textobjects.select')
  local move = require('nvim-treesitter-textobjects.move')
  local swap = require('nvim-treesitter-textobjects.swap')

  local select_modes = { 'x', 'o' }
  vim.keymap.set(select_modes, 'af', function()
    select.select_textobject('@function.outer', 'textobjects')
  end, { desc = 'Outer function' })
  vim.keymap.set(select_modes, 'if', function()
    select.select_textobject('@function.inner', 'textobjects')
  end, { desc = 'Inner function' })
  vim.keymap.set(select_modes, 'ac', function()
    select.select_textobject('@class.outer', 'textobjects')
  end, { desc = 'Outer class' })
  vim.keymap.set(select_modes, 'ic', function()
    select.select_textobject('@class.inner', 'textobjects')
  end, { desc = 'Inner class' })
  vim.keymap.set(select_modes, 'ab', function()
    select.select_textobject('@code_cell.outer', 'textobjects')
  end, { desc = 'Outer code block' })
  vim.keymap.set(select_modes, 'ib', function()
    select.select_textobject('@code_cell.inner', 'textobjects')
  end, { desc = 'Inner code block' })

  local move_modes = { 'n', 'x', 'o' }
  vim.keymap.set(move_modes, ']m', function()
    move.goto_next_start('@function.outer', 'textobjects')
  end, { desc = 'Next function start' })
  vim.keymap.set(move_modes, ']]', function()
    move.goto_next_start('@class.inner', 'textobjects')
  end, { desc = 'Next class start' })
  vim.keymap.set(move_modes, ']b', function()
    move.goto_next_start('@code_cell.outer', 'textobjects')
  end, { desc = 'Next code block start' })
  vim.keymap.set(move_modes, ']M', function()
    move.goto_next_end('@function.outer', 'textobjects')
  end, { desc = 'Next function end' })
  vim.keymap.set(move_modes, '][', function()
    move.goto_next_end('@class.outer', 'textobjects')
  end, { desc = 'Next class end' })
  vim.keymap.set(move_modes, ']B', function()
    move.goto_next_end('@code_cell.outer', 'textobjects')
  end, { desc = 'Next code block end' })
  vim.keymap.set(move_modes, '[m', function()
    move.goto_previous_start('@function.outer', 'textobjects')
  end, { desc = 'Previous function start' })
  vim.keymap.set(move_modes, '[[', function()
    move.goto_previous_start('@class.inner', 'textobjects')
  end, { desc = 'Previous class start' })
  vim.keymap.set(move_modes, '[b', function()
    move.goto_previous_start('@code_cell.outer', 'textobjects')
  end, { desc = 'Previous code block start' })
  vim.keymap.set(move_modes, '[M', function()
    move.goto_previous_end('@function.outer', 'textobjects')
  end, { desc = 'Previous function end' })
  vim.keymap.set(move_modes, '[]', function()
    move.goto_previous_end('@class.outer', 'textobjects')
  end, { desc = 'Previous class end' })
  vim.keymap.set(move_modes, '[B', function()
    move.goto_previous_end('@code_cell.outer', 'textobjects')
  end, { desc = 'Previous code block end' })

  vim.keymap.set('n', '<leader>sbl', function()
    swap.swap_next '@code_cell.outer'
  end, { desc = 'Swap code block with next' })
  vim.keymap.set('n', '<leader>sbh', function()
    swap.swap_previous '@code_cell.outer'
  end, { desc = 'Swap code block with previous' })
end

return {
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    lazy = false,
    build = ':TSUpdate',
    init = function()
      if vim.fn.has 'nvim-0.12' ~= 1 then
        return
      end

      vim.schedule(function()
        local legacy = vim.fn.stdpath 'data' .. '/lazy/nvim-treesitter/lua/nvim-treesitter/configs.lua'
        local missing = not vim.uv.fs_stat(vim.fn.stdpath 'data' .. '/lazy/nvim-treesitter/lua/nvim-treesitter/init.lua')
        if vim.uv.fs_stat(legacy) then
          vim.notify(
            'nvim-treesitter master is still installed (breaks Neovim 0.12 markdown/Avante). '
              .. 'Close ALL Neovim windows, then run :Lazy sync',
            vim.log.levels.ERROR
          )
        elseif missing then
          vim.notify(
            'nvim-treesitter is not installed. Run :Lazy sync to fetch the main branch.',
            vim.log.levels.ERROR
          )
        end
      end)

      install_missing_parsers()
    end,
    config = function()
      if vim.fn.has 'nvim-0.12' ~= 1 then
        local ok_configs, configs = pcall(require, 'nvim-treesitter.configs')
        if ok_configs and configs then
          configs.setup {
            auto_install = false,
            ensure_installed = PARSERS,
            highlight = { enable = true, additional_vim_regex_highlighting = false },
            indent = { enable = true },
          }
        end
        return
      end

      local ok, ts = pcall(require, 'nvim-treesitter')
      if not ok then
        vim.notify(
          'nvim-treesitter is missing. Run :Lazy sync, or close Neovim and reinstall the plugin.',
          vim.log.levels.ERROR
        )
        return
      end

      ts.setup()
      setup_highlight_and_indent()
      setup_incremental_selection()
      setup_textobjects()
    end,
    dependencies = {
      {
        'nvim-treesitter/nvim-treesitter-textobjects',
        branch = 'main',
        enabled = vim.fn.has 'nvim-0.12' == 1,
      },
    },
  },
}
