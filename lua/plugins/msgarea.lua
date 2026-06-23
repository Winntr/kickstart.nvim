return {
  {
    'edisj/msgarea.nvim',
    priority = 1100,
    cond = function()
      return vim.fn.has 'nvim-0.12' == 1
    end,
    init = function()
      vim.g.msgarea_max_height = 15
      vim.g.msgarea_min_height = 3
    end,
    config = function()
      local msgarea_util = require 'custom.msgarea'

      vim.keymap.set('n', '<M-n>', function()
        msgarea_util.toggle()
      end, { desc = 'Toggle msgarea' })

      vim.keymap.set('n', '<leader>ms', function()
        msgarea_util.show()
      end, { desc = 'Show msgarea' })

      vim.keymap.set('n', '<leader>mt', function()
        msgarea_util.toggle()
      end, { desc = 'Toggle msgarea' })

      vim.keymap.set('n', '<leader>mc', function()
        msgarea_util.close()
      end, { desc = 'Close msgarea' })

      vim.api.nvim_create_user_command('MsgareaShow', function()
        msgarea_util.show()
      end, { desc = 'Expand and focus msgarea' })

      vim.api.nvim_create_user_command('MsgareaToggle', function()
        msgarea_util.toggle()
      end, { desc = 'Toggle msgarea visibility' })

      vim.api.nvim_create_user_command('MsgareaClose', function()
        msgarea_util.close()
      end, { desc = 'Close all msgarea windows and collapse cmdheight' })

      -- ponytail: scroll in msgarea without click collapsing back to editor focus
      vim.api.nvim_create_autocmd('WinEnter', {
        callback = function(ev)
          if not msgarea_util.available() then
            return
          end
          local msgarea = require 'msgarea'
          for _, win in ipairs(msgarea.state.active_windows) do
            if win.winid == ev.win then
              vim.wo[ev.win].winfixbuf = true
              return
            end
          end
        end,
      })
    end,
  },
}
