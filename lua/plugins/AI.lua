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
        chat = { adapter = 'cursor_cli' },
        inline = { adapter = 'cursor_cli' },
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
  {
    'carlos-algms/agentic.nvim',

    --- @type agentic.PartialUserConfig
    opts = {
      -- Any ACP-compatible provider works. Built-in: "claude-agent-acp" | "gemini-acp" | "codex-acp" | "opencode-acp" | "cursor-acp" | "copilot-acp" | "auggie-acp" | "mistral-vibe-acp" | "cline-acp" | "goose-acp"
      provider = 'cursor-acp', -- setting the name here is all you need to get started
      acp_providers = {
        -- Cursor changed their CLI tool from cursor-agent to just agent
        ['cursor-acp'] = {
          -- Neovim on Windows often requires the exact extension ( .cmd or .exe ) to find the executable, even if it's on the PATH. Adjust as needed for your OS and installation method.
          command = vim.fn.has 'win32' == 1 and 'agent.cmd' or 'agent',
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
        '<leader>aaa',
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
        '<leader>aar', -- ai Restore
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
  {
    'ThePrimeagen/99',
    config = function()
      local _99 = require '99'

      -- For logging that is to a file if you wish to trace through requests
      -- for reporting bugs, i would not rely on this, but instead the provided
      -- logging mechanisms within 99.  This is for more debugging purposes
      local cwd = vim.uv.cwd()
      local basename = vim.fs.basename(cwd)
      _99.setup {
        -- provider = _99.Providers.ClaudeCodeProvider,  -- default: OpenCodeProvider
        logger = {
          level = _99.DEBUG,
          path = '/tmp/' .. basename .. '.99.debug',
          print_on_error = true,
        },
        -- When setting this to something that is not inside the CWD tools
        -- such as claude code or opencode will have permission issues
        -- and generation will fail refer to tool documentation to resolve
        -- https://opencode.ai/docs/permissions/#external-directories
        -- https://code.claude.com/docs/en/permissions#read-and-edit
        tmp_dir = './tmp',

        --- Completions: #rules and @files in the prompt buffer
        completion = {
          -- I am going to disable these until i understand the
          -- problem better.  Inside of cursor rules there is also
          -- application rules, which means i need to apply these
          -- differently
          -- cursor_rules = "<custom path to cursor rules>"

          --- A list of folders where you have your own SKILL.md
          --- Expected format:
          --- /path/to/dir/<skill_name>/SKILL.md
          ---
          --- Example:
          --- Input Path:
          --- "scratch/custom_rules/"
          ---
          --- Output Rules:
          --- {path = "scratch/custom_rules/vim/SKILL.md", name = "vim"},
          --- ... the other rules in that dir ...
          ---
          custom_rules = {
            'scratch/custom_rules/',
          },

          --- Configure @file completion (all fields optional, sensible defaults)
          files = {
            -- enabled = true,
            -- max_file_size = 102400,     -- bytes, skip files larger than this
            -- max_files = 5000,            -- cap on total discovered files
            -- exclude = { ".env", ".env.*", "node_modules", ".git", ... },
          },
          --- File Discovery:
          --- - In git repos: Uses `git ls-files` which automatically respects .gitignore
          --- - Non-git repos: Falls back to filesystem scanning with manual excludes
          --- - Both methods apply the configured `exclude` list on top of gitignore

          --- What autocomplete engine to use. Defaults to native (built-in) if not specified.
          source = 'native', -- "native" (default), "cmp", or "blink"
        },

        --- WARNING: if you change cwd then this is likely broken
        --- ill likely fix this in a later change
        ---
        --- md_files is a list of files to look for and auto add based on the location
        --- of the originating request.  That means if you are at /foo/bar/baz.lua
        --- the system will automagically look for:
        --- /foo/bar/AGENT.md
        --- /foo/AGENT.md
        --- assuming that /foo is project root (based on cwd)
        md_files = {
          'AGENT.md',
        },
      }

      -- take extra note that i have visual selection only in v mode
      -- technically whatever your last visual selection is, will be used
      -- so i have this set to visual mode so i dont screw up and use an
      -- old visual selection
      --
      -- likely ill add a mode check and assert on required visual mode
      -- so just prepare for it now
      vim.keymap.set('v', '<leader>9v', function()
        _99.visual()
      end)

      --- if you have a request you dont want to make any changes, just cancel it
      vim.keymap.set('n', '<leader>9x', function()
        _99.stop_all_requests()
      end)

      vim.keymap.set('n', '<leader>9s', function()
        _99.search()
      end)
    end,
  },
}
