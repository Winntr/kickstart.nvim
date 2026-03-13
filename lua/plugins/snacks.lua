return {
  {
    "folke/snacks.nvim",
    priority = 1000,
    -- lazy = true,
    module = 'snacks',
    event = 'VeryLazy',
    ---@type snacks.Config
    opts = {
      bigfile = { enabled = true },
      -- dashboard = { enabled = true },
      explorer = { enabled = true },
      indent = { enabled = true },
      input = { enabled = true },
      notifier = {
        enabled = true,
        timeout = 3000,
      },
      terminal = {
        win = {
          style = "terminal",
          position = "bottom",
        }
      },
      -- Lazygit integration
      lazygit = {
        enabled = true,
        configure = true,  -- auto-configure lazygit for Neovim
        win = {
          style = "lazygit",
          position = "float",
          border = "rounded",
          width = 0.9,
          height = 0.9,
          keys = {
            term_normal = false,
          },
        },
      },
      picker = {
        enabled = true,
        actions = {
          opencode_send = function(...) return require("opencode").snacks_picker_send(...) end,
        },
        win = {
          input = {
            keys = {
              ["<a-a>"] = { "opencode_send", mode = { "n", "i" } },
            },
          },
        },
      },
      quickfile = { enabled = true },
      scope = { enabled = true },
      scroll = { enabled = false },
      statuscolumn = { enabled = true },
      words = { enabled = true },
      styles = {
        notification = {
          -- wo = { wrap = true } -- Wrap notifications
        },
        lazygit = {
          width = 0.9,
          height = 0.9,
          keys = {
            term_normal = false,
          },
        },
      },
    },
    keys = {
      -- Terminal toggle works in both normal and terminal mode
      { "<C-\\>", function() Snacks.terminal() end, desc = "Toggle Terminal", mode = { "n", "t" } },
      -- Numbered terminals (like ToggleTerm's 1<C-\>, 2<C-\>, etc.)
      { "1<C-\\>", function() Snacks.terminal.toggle(nil, { cwd = vim.fn.getcwd(), env = { TERM_NUM = "1" } }) end, desc = "Toggle Terminal 1", mode = { "n", "t" } },
      { "2<C-\\>", function() Snacks.terminal.toggle(nil, { cwd = vim.fn.getcwd(), env = { TERM_NUM = "2" } }) end, desc = "Toggle Terminal 2", mode = { "n", "t" } },
      { "3<C-\\>", function() Snacks.terminal.toggle(nil, { cwd = vim.fn.getcwd(), env = { TERM_NUM = "3" } }) end, desc = "Toggle Terminal 3", mode = { "n", "t" } },
      { "4<C-\\>", function() Snacks.terminal.toggle(nil, { cwd = vim.fn.getcwd(), env = { TERM_NUM = "4" } }) end, desc = "Toggle Terminal 4", mode = { "n", "t" } },
      { "5<C-\\>", function() Snacks.terminal.toggle(nil, { cwd = vim.fn.getcwd(), env = { TERM_NUM = "5" } }) end, desc = "Toggle Terminal 5", mode = { "n", "t" } },
      -- Lazygit
      { "<leader>gg", function() Snacks.lazygit() end, desc = "Lazygit" },
      { "<leader>gf", function() Snacks.lazygit.log_file() end, desc = "Lazygit file history" },
      { "<leader>gl", function() Snacks.lazygit.log() end, desc = "Lazygit log (cwd)" },
    },
    init = function()
      vim.api.nvim_create_autocmd("User", {
        pattern = "VeryLazy",
        callback = function()
          -- Setup some globals for debugging (lazy-loaded)
          _G.dd = function(...)
            Snacks.debug.inspect(...)
          end
          _G.bt = function()
            Snacks.debug.backtrace()
          end

          -- Override print to use snacks for `:=` command
          if vim.fn.has("nvim-0.11") == 1 then
            vim._print = function(_, ...)
              dd(...)
            end
          else
            vim.print = _G.dd 
          end

        end,
      })
    end,
  },
}
