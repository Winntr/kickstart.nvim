return {
  {
    'olimorris/codecompanion.nvim',
    enabled = false,
    lazy = true,
    cmd = {
      'CodeCompanion',
      'CodeCompanionChat',
      'CodeCompanionActions',
      'CodeCompanionAdd',
    },
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-treesitter/nvim-treesitter',
    },
    opts = {
      interactions = {
        chat = { adapter = 'copilot', model = 'gpt-5.4-mini' },
        inline = { adapter = 'copilot', model = 'gpt-5-mini' },
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
