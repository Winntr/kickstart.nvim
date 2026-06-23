local function lazygit_ai_config_path()
  local path = vim.fn.stdpath 'cache' .. '/lazygit-ai-commit.yml'
  local ps1 = vim.fs.normalize(vim.fn.stdpath 'config' .. '/scripts/lazygit-ai-commit.ps1'):gsub('\\', '/')
  vim.fn.writefile({
    'customCommands:',
    '  - key: "G"',
    '    description: "AI commit message (Cursor agent)"',
    '    context: "files"',
    '    loadingText: "Generating commit message..."',
    '    prompts:',
    '      - type: "menu"',
    '        title: "Which changes?"',
    '        key: "Scope"',
    '        options:',
    '          - value: "staged"',
    '            name: "Staged only"',
    '            description: "git diff --cached"',
    '            key: "s"',
    '          - value: "all"',
    '            name: "All uncommitted"',
    '            description: "git diff HEAD"',
    '            key: "a"',
    '    command: \'powershell.exe -NoProfile -ExecutionPolicy Bypass -File "' .. ps1 .. '" -Scope {{.Form.Scope | quote}}\'',
    '    output: terminal',
  }, path)
  return path
end

local function with_lazygit_config(fn)
  return function(...)
    local ai_config = lazygit_ai_config_path()
    local files = vim.tbl_filter(function(v)
      return v ~= ''
    end, vim.split(vim.env.LG_CONFIG_FILE or '', ',', { plain = true }))
    if not vim.tbl_contains(files, ai_config) then
      table.insert(files, 1, ai_config)
      vim.env.LG_CONFIG_FILE = table.concat(files, ',')
    end
    return fn(...)
  end
end

return {
  {
    'folke/snacks.nvim',
    priority = 1000,
    lazy = false,
    module = 'snacks',
    opts = {
      bigfile = { enabled = true },
      explorer = { enabled = false },
      input = { enabled = true },
      notifier = { enabled = true, timeout = 3000 },
      picker = { enabled = false },
      quickfile = { enabled = true },
      scope = { enabled = true },
      scroll = { enabled = false },
      statuscolumn = { enabled = true },
      words = { enabled = true },
      terminal = {
        win = { style = 'terminal', position = 'bottom' },
      },
      lazygit = {
        enabled = true,
        configure = true,
        win = {
          style = 'lazygit',
          position = 'float',
          border = 'rounded',
          width = 0.9,
          height = 0.9,
        },
      },
    },
    keys = {
      {
        '<C-\\>',
        function()
          Snacks.terminal()
        end,
        desc = 'Toggle terminal',
        mode = { 'n', 't' },
      },
      {
        '<leader>gg',
        with_lazygit_config(function()
          Snacks.lazygit()
        end),
        desc = 'Lazygit',
      },
      {
        '<leader>gf',
        with_lazygit_config(function()
          Snacks.lazygit.log_file()
        end),
        desc = 'Lazygit file history',
      },
      {
        '<leader>gl',
        with_lazygit_config(function()
          Snacks.lazygit.log()
        end),
        desc = 'Lazygit log',
      },
    },
  },
}
