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
        msgarea_util.close()
      end, { desc = 'Close msgarea' })

      vim.keymap.set('n', '<leader>mc', function()
        msgarea_util.close()
      end, { desc = 'Close msgarea' })

      vim.api.nvim_create_user_command('MsgareaClose', function()
        msgarea_util.close()
      end, { desc = 'Close all msgarea windows and collapse cmdheight' })
    end,
  },
}
