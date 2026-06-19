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
      vim.keymap.set('n', '<M-n>', function()
        require('msgarea').close_all()
      end, { desc = 'Close msgarea' })
    end,
  },
}
