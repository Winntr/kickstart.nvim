return {
  {
    'piersolenski/wtf.nvim',
    init = function()
      require('custom.patches.wtf_cursor').apply()
    end,
    dependencies = {
      'nvim-lua/plenary.nvim',
      'MunifTanjim/nui.nvim',
      'folke/snacks.nvim',
    },
    config = function(_, opts)
      local setup_opts = vim.deepcopy(opts)
      -- Upstream validates provider name against built-ins during setup.
      -- Bootstrap with a built-in provider, then switch to our patched cursor provider.
      setup_opts.provider = 'copilot'
      require('wtf').setup(setup_opts)
      require('wtf.config').options.provider = 'cursor'
    end,
    opts = {
      provider = 'cursor',
      picker = 'snacks',
      providers = {
        cursor = {
          model_id = require('custom.cursor_agent').MODEL_COMPOSER_25,
        },
      },
    },
    keys = {
      {
        '<leader>awd',
        mode = { 'n', 'x' },
        function()
          require('wtf').diagnose()
        end,
        desc = 'Debug diagnostic with AI',
      },
      {
        '<leader>awf',
        mode = { 'n', 'x' },
        function()
          require('wtf').fix()
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
