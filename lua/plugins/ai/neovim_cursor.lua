return {
  {
    'felixcuello/neovim-cursor',
    event = 'VeryLazy',
    config = function()
      local esc = require 'custom.cursor_terminal_esc'
      -- ponytail: Windows `cursor` is the editor binary; `agent` is the CLI on PATH.
      local command = vim.fn.has 'win32' == 1 and 'agent' or 'cursor agent'
      require('neovim-cursor').setup {
        keybindings = {
          toggle = '<leader>aa',
          new = '<leader>an',
          select = '<leader>at',
          rename = '<leader>ar',
        },
        command = command,
        split = {
          position = 'right',
          size = 0.5,
        },
        term_opts = {
          on_open = function()
            esc.patch()
          end,
        },
      }

      vim.api.nvim_create_autocmd('BufWinEnter', {
        callback = function(args)
          if esc.is_cursor_agent_buf(args.buf) then
            vim.schedule(function()
              esc.patch(args.buf)
            end)
          end
        end,
      })
    end,
    keys = {
      {
        '<leader>aa',
        desc = 'Cursor agent toggle',
        mode = { 'n', 'v' },
      },
      { '<leader>an', desc = 'Cursor agent new' },
      { '<leader>at', desc = 'Cursor agent select' },
      { '<leader>ar', desc = 'Cursor agent rename' },
    },
  },
}
