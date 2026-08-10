local function harpoon()
  return require 'harpoon'
end

local function list()
  harpoon():setup()
  return harpoon():list()
end

local function select_slot(idx)
  local l = list()
  if not l:get(idx) then
    require('custom.msgarea').echo_warn(
      string.format('Harpoon slot %d is empty — use <leader>hs%d to set it', idx, idx)
    )
    return
  end
  l:select(idx)
end

local function set_slot(idx)
  local l = list()
  l:replace_at(idx, l.config.create_list_item(l.config))
  require('custom.msgarea').echo_status(
    string.format('Harpoon slot %d ← %s', idx, vim.fn.expand '%:.')
  )
end

return {
  {
    'ThePrimeagen/harpoon',
    branch = 'harpoon2',
    dependencies = { 'nvim-lua/plenary.nvim' },
    keys = {
      {
        '<leader>ha',
        function()
          list():add()
          require('custom.msgarea').echo_status('Added to harpoon: ' .. vim.fn.expand '%:.')
        end,
        desc = 'Harpoon add file',
      },
      {
        '<leader>hh',
        function()
          require('misc.pickers').harpoon()
        end,
        desc = 'Harpoon menu',
      },
      {
        '<leader>hn',
        function()
          list():next()
        end,
        desc = 'Harpoon next file',
      },
      {
        '<leader>hp',
        function()
          list():prev()
        end,
        desc = 'Harpoon previous file',
      },
      {
        '<leader>h1',
        function()
          select_slot(1)
        end,
        desc = 'Go to harpoon 1',
      },
      {
        '<leader>h2',
        function()
          select_slot(2)
        end,
        desc = 'Go to harpoon 2',
      },
      {
        '<leader>h3',
        function()
          select_slot(3)
        end,
        desc = 'Go to harpoon 3',
      },
      {
        '<leader>h4',
        function()
          select_slot(4)
        end,
        desc = 'Go to harpoon 4',
      },
      {
        '<leader>hs1',
        function()
          set_slot(1)
        end,
        desc = 'Set harpoon slot 1',
      },
      {
        '<leader>hs2',
        function()
          set_slot(2)
        end,
        desc = 'Set harpoon slot 2',
      },
      {
        '<leader>hs3',
        function()
          set_slot(3)
        end,
        desc = 'Set harpoon slot 3',
      },
      {
        '<leader>hs4',
        function()
          set_slot(4)
        end,
        desc = 'Set harpoon slot 4',
      },
    },
    config = function()
      require('harpoon'):setup()
    end,
  },
}
