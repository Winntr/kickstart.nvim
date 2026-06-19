return {
  {
    'L3MON4D3/LuaSnip',
    event = 'InsertEnter',
    dependencies = {
      'rafamadriz/friendly-snippets',
    },
    config = function()
      local luasnip = require 'luasnip'

      -- for friendly snippets
      require('luasnip.loaders.from_vscode').lazy_load()
      -- for custom snippets
      require('luasnip.loaders.from_vscode').lazy_load { paths = { vim.fn.stdpath 'config' .. '/snips' } }
      -- link rmarkdown to markdown snippets
      luasnip.filetype_extend('rmarkdown', { 'markdown' })

      vim.keymap.set({ 'i', 's' }, '<C-l>', function()
        if luasnip.expand_or_locally_jumpable() then
          luasnip.expand_or_jump()
        end
      end, { desc = 'Snippet jump forward' })

      vim.keymap.set({ 'i', 's' }, '<C-h>', function()
        if luasnip.locally_jumpable(-1) then
          luasnip.jump(-1)
        end
      end, { desc = 'Snippet jump backward' })
    end,
  },
}
