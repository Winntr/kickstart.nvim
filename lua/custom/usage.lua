--- Track keymap, plugin, and command usage for config slimming.
local M = {}

local PATH = vim.fn.stdpath 'data' .. '/usage.json'
local FLUSH_MS = 30000

local data = {
  version = 1,
  keymaps = {},
  plugins = {},
  commands = {},
}

local catalog = {}
local dirty = false
local patched = false
local orig_keymap_set = vim.keymap.set

local function now()
  return os.time()
end

local function reset_msgarea()
  if vim.fn.has 'nvim-0.12' == 1 then
    pcall(function()
      require('custom.msgarea').reset()
    end)
  end
end

local function load()
  if vim.fn.filereadable(PATH) ~= 1 then
    return
  end
  local lines = vim.fn.readfile(PATH)
  if #lines == 0 then
    return
  end
  local ok, decoded = pcall(vim.json.decode, table.concat(lines, '\n'))
  if ok and type(decoded) == 'table' then
    data = vim.tbl_deep_extend('force', data, decoded)
  end
end

local function save()
  vim.fn.mkdir(vim.fn.fnamemodify(PATH, ':h'), 'p')
  vim.fn.writefile({ vim.json.encode(data) }, PATH)
  dirty = false
end

local function schedule_flush()
  vim.defer_fn(function()
    if dirty then
      save()
    end
    schedule_flush()
  end, FLUSH_MS)
end

function M.record_keymap(lhs, desc)
  if lhs == nil or lhs == '' then
    return
  end
  desc = desc or catalog[lhs] or ''
  if desc ~= '' then
    catalog[lhs] = desc
  end

  local entry = data.keymaps[lhs] or { count = 0, desc = desc, last = 0 }
  entry.count = (entry.count or 0) + 1
  entry.last = now()
  if desc ~= '' then
    entry.desc = desc
  end
  data.keymaps[lhs] = entry
  dirty = true
end

function M.record_plugin(name)
  if name == nil or name == '' then
    return
  end
  local entry = data.plugins[name] or { loads = 0, last = 0 }
  entry.loads = (entry.loads or 0) + 1
  entry.last = now()
  data.plugins[name] = entry
  dirty = true
end

function M.record_command(name)
  if name == nil or name == '' then
    return
  end
  local entry = data.commands[name] or { count = 0, last = 0 }
  entry.count = (entry.count or 0) + 1
  entry.last = now()
  data.commands[name] = entry
  dirty = true
end

local function wrap_rhs(lhs, rhs, opts)
  if type(rhs) == 'function' then
    return function(...)
      M.record_keymap(lhs, opts.desc)
      return rhs(...)
    end
  end

  if type(rhs) ~= 'string' or opts.expr then
    return rhs
  end

  local cmd = rhs:match '^<cmd>(.-)<cr>$'
  if cmd then
    return function()
      M.record_keymap(lhs, opts.desc)
      vim.cmd(cmd)
    end
  end

  local keys = vim.api.nvim_replace_termcodes(rhs, true, false, true)
  return function()
    M.record_keymap(lhs, opts.desc)
    vim.api.nvim_feedkeys(keys, 'n', false)
  end
end

function M.patch_keymap()
  if patched then
    return
  end
  patched = true

  vim.keymap.set = function(modes, lhs, rhs, opts)
    opts = vim.deepcopy(opts or {})
    if opts.desc then
      catalog[lhs] = opts.desc
    end
    rhs = wrap_rhs(lhs, rhs, opts)
    return orig_keymap_set(modes, lhs, rhs, opts)
  end
end

function M.scan_keymaps()
  for _, mode in ipairs { 'n', 'v', 'x', 's', 'o', 'i', 'c', 't' } do
    for _, map in ipairs(vim.api.nvim_get_keymap(mode)) do
      if map.desc and map.desc ~= '' and map.lhs then
        catalog[map.lhs] = map.desc
        if not data.keymaps[map.lhs] then
          data.keymaps[map.lhs] = { count = 0, desc = map.desc, last = 0 }
        elseif data.keymaps[map.lhs].desc == '' then
          data.keymaps[map.lhs].desc = map.desc
        end
      end
    end
  end
end

local function format_time(ts)
  if not ts or ts == 0 then
    return 'never'
  end
  return os.date('%Y-%m-%d %H:%M', ts)
end

local function ensure_pick()
  local ok = pcall(require, 'mini.pick')
  if ok then
    return true
  end
  local lazy_ok = pcall(require, 'lazy')
  if lazy_ok then
    require('lazy').load { plugins = { 'mini.nvim' } }
  end
  return pcall(require, 'mini.pick')
end

local function pick_items(items, title)
  if not ensure_pick() then
    require('custom.msgarea').echo_warn 'mini.pick not available'
    return
  end
  reset_msgarea()

  require('mini.pick').start {
    source = {
      name = title,
      items = items,
      show = function(item)
        return { { item.text, 'Normal' } }
      end,
      choose = function(item)
        if item.action then
          item.action()
        end
      end,
    },
  }
end

local function show_top_keymaps()
  local items = {}
  for lhs, entry in pairs(data.keymaps) do
    if (entry.count or 0) > 0 then
      items[#items + 1] = {
        text = string.format('%4d  %s  %s', entry.count, lhs, entry.desc or ''),
        sort_key = entry.count,
      }
    end
  end
  table.sort(items, function(a, b)
    return a.sort_key > b.sort_key
  end)
  pick_items(items, 'Top keymaps')
end

local function show_unused_keymaps()
  local items = {}
  for lhs, entry in pairs(data.keymaps) do
    if (entry.count or 0) == 0 then
      items[#items + 1] = {
        text = string.format('%s  %s', lhs, entry.desc or ''),
        sort_key = lhs,
      }
    end
  end
  table.sort(items, function(a, b)
    return a.sort_key < b.sort_key
  end)
  pick_items(items, 'Unused keymaps')
end

local function show_plugin_loads()
  local items = {}
  for name, entry in pairs(data.plugins) do
    items[#items + 1] = {
      text = string.format('%4d  %s  last %s', entry.loads or 0, name, format_time(entry.last)),
      sort_key = entry.loads or 0,
    }
  end
  table.sort(items, function(a, b)
    return a.sort_key > b.sort_key
  end)
  pick_items(items, 'Plugin loads')
end

local function show_never_loaded()
  local items = {}
  local ok, lazy_config = pcall(require, 'lazy.core.config')
  if not ok then
    require('custom.msgarea').echo_warn 'lazy.nvim not available'
    return
  end

  for _, plugin in pairs(lazy_config.plugins) do
    local entry = data.plugins[plugin.name]
    if not entry or (entry.loads or 0) == 0 then
      local state = plugin._.loaded and 'loaded (untracked)' or 'never loaded'
      if plugin._.cond == false or plugin.enabled == false then
        state = 'disabled'
      end
      items[#items + 1] = {
        text = string.format('%s  %s', plugin.name, state),
        sort_key = plugin.name,
      }
    end
  end
  table.sort(items, function(a, b)
    return a.sort_key < b.sort_key
  end)
  pick_items(items, 'Never loaded plugins')
end

function M.report()
  if not ensure_pick() then
    require('custom.msgarea').echo_warn 'mini.pick not available'
    return
  end
  reset_msgarea()
  require('mini.pick').start {
    source = {
      name = 'Usage report',
      items = {
        { text = 'Top keymaps', action = show_top_keymaps },
        { text = 'Unused keymaps', action = show_unused_keymaps },
        { text = 'Plugin loads', action = show_plugin_loads },
        { text = 'Never loaded plugins', action = show_never_loaded },
      },
      choose = function(item)
        if item.action then
          item.action()
        end
      end,
    },
  }
end

function M.reset()
  data.keymaps = {}
  data.plugins = {}
  data.commands = {}
  for lhs, desc in pairs(catalog) do
    data.keymaps[lhs] = { count = 0, desc = desc, last = 0 }
  end
  dirty = true
  save()
end

function M.setup()
  load()
  schedule_flush()

  vim.api.nvim_create_autocmd('VimLeavePre', {
    callback = function()
      if dirty then
        save()
      end
    end,
  })

  vim.api.nvim_create_autocmd('User', {
    pattern = 'LazyLoad',
    callback = function(ev)
      M.record_plugin(ev.data)
    end,
  })

  vim.api.nvim_create_autocmd('User', {
    pattern = 'LazyDone',
    callback = function()
      M.scan_keymaps()
      if dirty then
        save()
      end
    end,
    once = true,
  })

  vim.api.nvim_create_autocmd('CmdlineLeave', {
    callback = function()
      local cmd = vim.fn.getcmdline()
      local name = cmd:match '^%s*(%S+)'
      if name and name:sub(1, 1) ~= '/' and name:sub(1, 1) ~= '?' then
        M.record_command(name)
      end
    end,
  })

  vim.api.nvim_create_user_command('UsageReport', function()
    M.report()
  end, { desc = 'Open usage report picker' })

  vim.api.nvim_create_user_command('UsageReset', function()
    M.reset()
    require('custom.msgarea').echo_status 'Usage counters reset'
  end, { desc = 'Reset usage counters' })
end

return M
