-- plugins for notetaking and knowledge management
return {
  {
    'nvim-neorg/neorg',
    enabled = false,
    config = function()
      require('neorg').setup {}
    end,
  },
}
