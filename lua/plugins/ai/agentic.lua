local cursor_provider = require('custom.cursor_agent').agentic_acp_provider()

return {
  {
    'carlos-algms/agentic.nvim',
    enabled = false,
    init = function()
      require('custom.patches.agentic_acp_transport').apply()
    end,

    --- @type agentic.PartialUserConfig
    opts = {
      -- Any ACP-compatible provider works. Built-in: "claude-agent-acp" | "gemini-acp" | "codex-acp" | "opencode-acp" | "cursor-acp" | "copilot-acp" | "auggie-acp" | "mistral-vibe-acp" | "cline-acp" | "goose-acp" | "kiro-acp" | "pi-acp"
      provider = 'cursor-acp', -- setting the name here is all you need to get started
      acp_providers = {
        ['cursor-acp'] = {
          command = cursor_provider.command,
          args = cursor_provider.args,
          env = cursor_provider.env,
        },
      },
    },
    -- these are just suggested keymaps; customize as desired
    keys = {
      {
        '<leader>aat',
        function()
          require('agentic').toggle()
        end,
        mode = { 'n', 'v', 'i' },
        desc = 'Toggle Agentic Chat',
      },
      {
        '<C-a>a',
        function()
          require('agentic').add_selection_or_file_to_context()
        end,
        mode = { 'n', 'v' },
        desc = 'Add file or selection to Agentic to Context',
      },
      {
        '<leader>aan',
        function()
          require('agentic').new_session()
        end,
        mode = { 'n', 'v', 'i' },
        desc = 'New Agentic Session',
      },
      {
        '<A-i>r', -- ai Restore
        function()
          require('agentic').restore_session()
        end,
        desc = 'Agentic Restore session',
        silent = true,
        mode = { 'n', 'v', 'i' },
      },
      {
        '<leader>aad', -- ai Diagnostics
        function()
          require('agentic').add_current_line_diagnostics()
        end,
        desc = 'Add current line diagnostic to Agentic',
        mode = { 'n' },
      },
      {
        '<leader>aaD', -- ai all Diagnostics
        function()
          require('agentic').add_buffer_diagnostics()
        end,
        desc = 'Add all buffer diagnostics to Agentic',
        mode = { 'n' },
      },
    },
  },
}
