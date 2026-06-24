return {
  {
    'felixcuello/neovim-cursor',
    event = 'VeryLazy',
    config = function()
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
      }
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
