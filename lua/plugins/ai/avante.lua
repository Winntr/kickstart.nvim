local cursor_provider = require('custom.cursor_agent').acp_provider(
  require('custom.cursor_agent').MODEL_COMPOSER_25
)

local function avante_keys()
  local api = function()
    return require 'avante.api'
  end
  local avante = function()
    return require 'avante'
  end

  return {
    {
      '<leader>aa',
      function()
        api().ask()
      end,
      desc = 'Avante ask',
      mode = { 'n', 'v' },
    },
    {
      '<leader>an',
      function()
        api().ask { new_chat = true }
      end,
      desc = 'Avante new chat',
      mode = { 'n', 'v' },
    },
    {
      '<leader>az',
      function()
        api().zen_mode()
      end,
      desc = 'Avante zen mode',
      mode = { 'n', 'v' },
    },
    {
      '<leader>ae',
      function()
        api().edit()
      end,
      desc = 'Avante edit selection',
      mode = 'v',
    },
    {
      '<leader>aS',
      function()
        api().stop()
      end,
      desc = 'Avante stop request',
    },
    {
      '<leader>ar',
      function()
        api().refresh()
      end,
      desc = 'Avante refresh',
    },
    {
      '<leader>af',
      function()
        api().focus()
      end,
      desc = 'Avante focus sidebar',
    },
    {
      '<leader>at',
      function()
        avante().toggle_sidebar()
      end,
      desc = 'Avante toggle sidebar',
    },
    {
      '<leader>ad',
      function()
        avante().toggle.debug()
      end,
      desc = 'Avante toggle debug',
    },
    {
      '<leader>aC',
      function()
        avante().toggle.selection()
      end,
      desc = 'Avante toggle selection',
    },
    {
      '<leader>as',
      function()
        avante().toggle.suggestion()
      end,
      desc = 'Avante toggle suggestions',
    },
    {
      '<leader>aR',
      function()
        require('avante.repo_map').show()
      end,
      desc = 'Avante repo map',
    },
    {
      '<leader>a?',
      function()
        api().select_model()
      end,
      desc = 'Avante select model',
    },
    {
      '<leader>ah',
      function()
        api().select_history()
      end,
      desc = 'Avante chat history',
    },
    {
      '<leader>aM',
      function()
        api().select_acp_model()
      end,
      desc = 'Avante ACP model',
    },
    {
      '<leader>am',
      function()
        api().select_acp_mode()
      end,
      desc = 'Avante ACP mode',
    },
    {
      '<leader>aB',
      function()
        api().add_buffer_files()
      end,
      desc = 'Avante add all buffers',
    },
    {
      '<leader>ac',
      function()
        local sidebar = select(1, avante().get(false))
        if not sidebar or not sidebar:is_open() then
          avante().open_sidebar { ask = false }
          sidebar = select(1, avante().get(false))
        end
        if sidebar and sidebar:is_open() then
          sidebar.file_selector:add_current_buffer()
        end
      end,
      desc = 'Avante add current file',
    },
  }
end

return {
  {
    'yetone/avante.nvim',
    -- Disabled: Cursor ACP is unstable; use felixcuello/neovim-cursor (terminal `cursor agent`) instead.
    enabled = false,
    version = false,
    build = vim.fn.has 'win32' == 1
        and 'powershell -NoProfile -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false'
        or 'make',
    event = 'VeryLazy',
    init = function()
      require('custom.patches.agentic_acp_transport').apply()
    end,
    config = function(_, opts)
      require('custom.patches.avante_acp_selector').apply()
      require('avante').setup(opts)
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
        auto_set_keymaps = false,
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
    keys = avante_keys(),
    dependencies = {
      'nvim-lua/plenary.nvim',
      'MunifTanjim/nui.nvim',
      'nvim-mini/mini.pick',
      'saghen/blink.cmp',
      'saghen/blink.compat',
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
