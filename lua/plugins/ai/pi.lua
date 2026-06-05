return {
  {
    'pablopunk/pi.nvim',
    provider = 'copilot',
    model = 'gpt-5.4-mini',
    thinking = 'low',
    skills = true,
    extensions = true,

    --- Pi.nvim `keys`: each entry's first string is the map LHS (what you press); the second is
    --- the RHS (usually `<cmd>...<cr>`). The `<leader>ap*` sequences below are examples only—swap
    --- them for chords that fit your layout and do not collide with other Lazy/LSP/which-key maps.
    --- `mode` is passed through to `vim.keymap.set`; `desc` is shown in which-key and similar UIs
    --- (see `:help map-which-key` for integrating descriptions with your picker).
    keys = {
      {
        '<leader>apa',
        '<cmd>PiAsk<cr>',
        mode = 'n',
        desc = 'Ask Pi coding agent',
      },
      {
        '<leader>aps',
        '<cmd>PiAskSelection<cr>',
        mode = 'v',
        desc = 'Ask Pi about visual selection',
      },
      {
        '<leader>apc',
        '<cmd>PiCancel<cr>',
        mode = 'n',
        desc = 'Cancel Pi agent request',
      },
      {
        '<leader>apl',
        '<cmd>PiLog<cr>',
        mode = 'n',
        desc = 'Open Pi agent session log',
      },
    },
  },
}
