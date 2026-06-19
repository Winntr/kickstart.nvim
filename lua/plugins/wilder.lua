return {
  {
    'gelguy/wilder.nvim',
    enabled = true,
    event = 'CmdlineEnter',
    dependencies = {
      { 'romgrk/fzy-lua-native', build = 'make', cond = vim.fn.has 'win32' == 0 },
    },
    config = function()
      local wilder = require 'wilder'
      wilder.setup { modes = { ':', '/', '?' } }

      -- Detect if native fuzzy is available (fails on Windows or if not compiled)
      local has_fzy, _ = pcall(require, 'fzy-lua-native')

      local fuzzy_filter = has_fzy and wilder.lua_fzy_filter() or wilder.vim_fuzzy_filter()

      local highlighter = has_fzy and wilder.lua_fzy_highlighter() or wilder.basic_highlighter()

      -- Pure Lua pipeline (no Python dependency)
      wilder.set_option('pipeline', {
        wilder.branch(
          wilder.cmdline_pipeline {
            language = 'lua',
            fuzzy = 1,
            fuzzy_filter = fuzzy_filter,
          },
          wilder.search_pipeline()
        ),
      })

      wilder.set_option(
        'renderer',
        wilder.popupmenu_renderer {
          highlighter = highlighter,
          left = { ' ', wilder.popupmenu_devicons() },
          right = { ' ', wilder.popupmenu_scrollbar() },
        }
      )
    end,
  },
}
