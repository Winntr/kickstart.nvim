return {
  {
    'kevalin/mermaid.nvim',
    ft = { 'markdown', 'mermaid', 'Avante' },
    dependencies = {
      { 'nvim-treesitter/nvim-treesitter', branch = 'main' },
    },
    config = function()
      require('mermaid').setup {
        lint = { enabled = false },
        preview = {
          renderer = 'mermaid.js',
        },
      }
      require('custom.mermaid_markdown').setup()
    end,
    keys = {
      { '<leader>um', desc = 'Mermaid preview (cursor block)' },
      { '<leader>uM', desc = 'Mermaid render inline (cursor block)' },
    },
  },
}
