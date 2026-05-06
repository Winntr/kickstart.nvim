return {
  {
    'zbirenbaum/copilot.lua',
    enabled = function()
      return not vim.g.vscode
    end,
    cmd = 'Copilot',
    event = 'InsertEnter',
    config = function()
      require('copilot').setup {
        suggestion = {
          enabled = true,
          auto_trigger = true,
          debounce = 100,
          keymap = {
            accept = '<C-y>',
            accept_word = false,
            accept_line = false,
            next = '<M-]>',
            prev = '<M-[>',
            dismiss = '<C-]>',
          },
        },
        panel = { enabled = true },
        filetypes = {
          yaml = true,
          markdown = true,
        },
      }
    end,
  },
  {
    'piersolenski/wtf.nvim',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'MunifTanjim/nui.nvim',
    },
    opts = {
      provider = 'copilot',
    },
    keys = {
      {
        '<leader>wd',
        mode = { 'n', 'x' },
        function()
          require('wtf').diagnose()
        end,
        desc = 'Debug diagnostic with AI',
      },
      {
        '<leader>wf',
        mode = { 'n', 'x' },
        function()
          require('wtf').fix()
        end,
        desc = 'Fix diagnostic with AI',
      },
      {
        '<leader>ws',
        mode = { 'n' },
        function()
          require('wtf').search()
        end,
        desc = 'Search diagnostic with Google',
      },
      {
        '<leader>wh',
        mode = { 'n' },
        function()
          require('wtf').history()
        end,
        desc = 'Populate quickfix with diagnostic history',
      },
    },
  },
  {
    'olimorris/codecompanion.nvim',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-treesitter/nvim-treesitter',
    },
    opts = {
      interactions = {
        chat = { adapter = 'copilot' },
        inline = { adapter = 'copilot' },
      },
      adapters = {
        opts = {
          show_model_choices = true,
        },
        http = {
          copilot = function()
            -- Require the raw base adapter to bypass 'extend' (which breaks the menu)
            -- and 'resolve' (which causes the stack overflow).
            local copilot_mod = require 'codecompanion.adapters.http.copilot'

            -- Initialize the adapter (handles both factory function or direct table returns)
            local adapter = type(copilot_mod) == 'function' and copilot_mod() or copilot_mod

            -- Safely mutate only the default string, preserving the dynamic 'choices' function
            adapter.schema.model.default = 'gpt-5.4-mini'
            -- 2. Intercept the payload and remove the unsupported 'top_p' parameter
            local original_form_parameters = adapter.handlers.form_parameters
            adapter.handlers.form_parameters = function(self, params, messages)
              local payload = original_form_parameters(self, params, messages)
              payload.top_p = nil -- Strip top_p to prevent the 400 error
              return payload
            end

            return adapter
          end,
        },
      },
    },
  },
}
