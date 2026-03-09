return {
  {
    'sindrets/diffview.nvim',
    cmd = { 'DiffviewOpen', 'DiffviewClose', 'DiffviewToggle', 'DiffviewFileHistory' },
    config = function()
      local actions = require('diffview.actions')

      require('diffview').setup({
        enhanced_diff_hl = true,
        view = {
          default = {
            layout = 'diff2_horizontal',
          },
          merge_tool = {
            layout = 'diff3_horizontal',
          },
          file_history = {
            layout = 'diff2_horizontal',
          },
        },
        keymaps = {
          disable_defaults = false,
          file_panel = {
            -- Disable s/S to avoid conflict with flash.nvim
            { 'n', 's', false },
            { 'n', 'S', false },
            -- Use 'ga' for staging (mnemonic: git add)
            { 'n', 'ga', actions.toggle_stage_entry, { desc = 'Stage / unstage the selected entry' } },
            { 'n', 'gA', actions.stage_all, { desc = 'Stage all entries' } },
            { 'n', 'gU', actions.unstage_all, { desc = 'Unstage all entries' } },
          },
          view = {
            -- Disable s/S in view to avoid conflict with flash.nvim
            { 'n', 's', false },
            { 'n', 'S', false },
          },
        },
      })
    end,
  },

  -- Inline merge conflict resolution
  -- Highlights conflict markers and provides granular actions (ours/theirs/both/base/none)
  -- See: GitHowTo/gitconflict.md
  {
    'akinsho/git-conflict.nvim',
    version = '*',
    event = 'BufReadPre',
    cmd = {
      'GitConflictChooseOurs',
      'GitConflictChooseTheirs',
      'GitConflictChooseBoth',
      'GitConflictChooseBase',
      'GitConflictChooseNone',
      'GitConflictListQf',
      'GitConflictRefresh',
    },
    opts = {
      default_mappings = {
        ours = 'co',
        theirs = 'ct',
        none = 'c0',
        both = 'cb',
        next = ']x',
        prev = '[x',
      },
      default_commands = true,
      disable_diagnostics = true,
      list_opener = 'copen',
      highlights = {
        incoming = 'DiffAdd',
        current = 'DiffText',
      },
    },
  },

  -- Neogit disabled - too slow on Windows (~3s to open)
  -- {
  --   "NeogitOrg/neogit",
  --   lazy = true,
  --   dependencies = {
  --     "nvim-lua/plenary.nvim",
  --     "sindrets/diffview.nvim",
  --     "nvim-telescope/telescope.nvim",
  --     "folke/snacks.nvim",
  --   },
  --   cmd = "Neogit",
  --   keys = {
  --     { "<leader>gn", "<cmd>Neogit<cr>", desc = "Neogit UI" }
  --   }
  -- },
}
