return {
  {
    'piersolenski/wtf.nvim',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'MunifTanjim/nui.nvim',
      'folke/snacks.nvim',
    },
    opts = {
      -- Built-in provider is only used for history/search UI paths.
      -- Diagnose/fix AI calls go through `custom.wtf_cursor` (Cursor CLI --print).
      provider = 'ollama',
      picker = 'snacks',
      providers = {
        ollama = {
          model_id = vim.env.OLLAMA_MODEL_ID or 'unused',
        },
      },
    },
    keys = {
      {
        '<leader>awd',
        mode = { 'n', 'x' },
        function()
          require('custom.wtf_cursor').diagnose()
        end,
        desc = 'Debug diagnostic with AI',
      },
      {
        '<leader>awf',
        mode = { 'n', 'x' },
        function()
          require('custom.wtf_cursor').fix()
        end,
        desc = 'Fix diagnostic with AI',
      },
      {
        '<leader>aws',
        mode = { 'n' },
        function()
          require('wtf').search()
        end,
        desc = 'Search diagnostic with Google',
      },
      {
        '<leader>awh',
        mode = { 'n' },
        function()
          require('wtf').history()
        end,
        desc = 'Populate quickfix with diagnostic history',
      },
    },
  },
}
