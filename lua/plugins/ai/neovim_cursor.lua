return {
  {
    'felixcuello/neovim-cursor',
    event = 'VeryLazy',
    config = function()
      local esc = require 'custom.cursor_terminal_esc'
      local chat = require 'custom.cursor_chat'
      local done = require 'custom.cursor_done'
      -- ponytail: Windows `cursor` is the editor binary; `agent` is the CLI on PATH.
      local command = vim.fn.has 'win32' == 1 and 'agent' or 'cursor agent'
      local merged_config = {
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
            vim.schedule(function()
              local tabs = require('neovim-cursor').tabs
              for _, term in ipairs(tabs.list_terminals()) do
                local state = require('neovim-cursor').terminal.get_state(term.id)
                if state.buf then
                  done.watch_buf(state.buf)
                end
              end
            end)
          end,
        },
      }

      done.setup()
      require('neovim-cursor').setup(merged_config)
      chat.setup(merged_config)

      pcall(vim.keymap.del, 'v', '<leader>aa')
      vim.keymap.set('v', '<leader>aa', function()
        local esc_key = vim.api.nvim_replace_termcodes('<Esc>', true, false, true)
        vim.api.nvim_feedkeys(esc_key, 'x', false)
        vim.schedule(chat.send_selection)
      end, { desc = 'Send selection to agent', silent = true })

      chat.map {
        { '<leader>as', chat.send_selection, mode = 'v', desc = 'Send selection to agent' },
        { '<leader>ac', chat.send_current_buffer, mode = 'n', desc = 'Send current file to agent' },
        { '<leader>aB', chat.send_all_buffers, mode = 'n', desc = 'Send all open buffers to agent' },
        { '<leader>af', chat.focus_agent, mode = 'n', desc = 'Focus agent terminal' },
      }

      vim.api.nvim_create_autocmd('BufWinEnter', {
        callback = function(args)
          if esc.is_cursor_agent_buf(args.buf) then
            vim.schedule(function()
              esc.patch(args.buf)
              done.watch_buf(args.buf)
            end)
          end
        end,
      })
    end,
    keys = {
      {
        '<leader>aa',
        desc = 'Cursor agent toggle / send selection',
        mode = { 'n', 'v' },
      },
      { '<leader>an', desc = 'Cursor agent new' },
      { '<leader>at', desc = 'Cursor agent select' },
      { '<leader>ar', desc = 'Cursor agent rename' },
      { '<leader>as', desc = 'Send selection to agent', mode = 'v' },
      { '<leader>ac', desc = 'Send current file to agent' },
      { '<leader>aB', desc = 'Send all open buffers to agent' },
      { '<leader>af', desc = 'Focus agent terminal' },
    },
  },
}
