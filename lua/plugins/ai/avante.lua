local cursor_provider = require('custom.cursor_agent').acp_provider()

return {
  {
    'yetone/avante.nvim',
    version = false,
    build = vim.fn.has 'win32' == 1
        and 'powershell -NoProfile -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false'
        or 'make',
    event = 'VeryLazy',
    init = function()
      require('custom.patches.agentic_acp_transport').apply()
    end,
    config = function()
      require('custom.patches.avante_acp_selector').apply()
    end,
    opts = {
      provider = 'cursor-acp',
      instructions_file = 'avante.md',
      mode = 'agentic',
      selector = {
        provider = 'mini_pick',
      },
      input = {
        provider = 'snacks',
      },
      behaviour = {
        auto_suggestions = false,
        auto_set_keymaps = true,
        auto_approve_tool_permissions = true,
        acp_follow_agent_locations = true,
      },
      acp_providers = {
        ['cursor-acp'] = {
          command = cursor_provider.command,
          args = cursor_provider.args,
          env = cursor_provider.env,
        },
      },
    },
    dependencies = {
      'nvim-lua/plenary.nvim',
      'MunifTanjim/nui.nvim',
      'nvim-mini/mini.pick',
      'hrsh7th/nvim-cmp',
      'folke/snacks.nvim',
      'MeanderingProgrammer/render-markdown.nvim',
      {
        'HakonHarnes/img-clip.nvim',
        event = 'VeryLazy',
        opts = {
          default = {
            use_absolute_path = true,
            embed_image_as_base64 = false,
            prompt_for_file_name = false,
          },
        },
      },
    },
  },
}
