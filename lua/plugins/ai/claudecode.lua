return {
  'coder/claudecode.nvim',
  dependencies = { 'folke/snacks.nvim' },
  opts = {
    terminal = {
      split_side = 'right',
      split_width_percentage = 0.55,
    },
  },
  config = function(_, opts)
    require('claudecode').setup(opts)

    -- Fullscreen = Claude terminal in its own tab (toggle again to close the tab).
    local function fullscreen_open()
      vim.cmd 'ClaudeCodeFocus'
      vim.cmd 'tab split'
      vim.t.claude_fullscreen = true
      vim.cmd 'startinsert'
    end

    local function fullscreen_toggle()
      if vim.t.claude_fullscreen then
        pcall(vim.cmd, 'tabclose')
      else
        fullscreen_open()
      end
    end

    -- Vibe mode = fullscreen + auto-accept every nvim diff Claude proposes.
    -- ponytail: only skips the nvim diff review; Claude's own permission prompts still apply.
    local vibe = false

    vim.api.nvim_create_autocmd('User', {
      pattern = 'ClaudeCodeDiffOpened',
      callback = function(args)
        if not vibe then
          return
        end
        local win = args.data and args.data.diff_window
        vim.schedule(function()
          if win and vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_win_call(win, function()
              pcall(require('claudecode.diff').accept_current_diff)
            end)
          end
        end)
      end,
    })

    -- Forward Claude's notification (OSC 9 from preferredNotifChannel=iterm2_with_bell) to the outer terminal as a BEL + vim.notify.
    -- ponytail: fires for any :terminal buffer that emits OSC 9, not just Claude's.
    vim.api.nvim_create_autocmd('TermRequest', {
      callback = function(args)
        local seq = args.data and args.data.sequence or ''
        local msg = seq:match '^\27%]9;(.*)$'
        -- OSC 9;4 is ConEmu progress, not a notification
        if msg and not msg:match '^4;' then
          vim.fn.chansend(vim.v.stderr, '\a')
          vim.notify(msg, vim.log.levels.INFO, { title = 'Claude Code' })
        end
      end,
    })

    vim.keymap.set('n', '<leader>akz', fullscreen_toggle, { desc = 'Claude fullscreen toggle' })
    vim.keymap.set('n', '<leader>akv', function()
      vibe = not vibe
      if vibe and not vim.t.claude_fullscreen then
        fullscreen_open()
      elseif not vibe and vim.t.claude_fullscreen then
        pcall(vim.cmd, 'tabclose')
      end
      vim.notify('Claude vibe mode ' .. (vibe and 'ON (auto-accept diffs)' or 'OFF'))
    end, { desc = 'Claude vibe mode toggle' })
  end,
  -- Claude lives on <leader>ai (toggle) + <leader>ak* (everything else)
  keys = {
    { '<leader>akz', desc = 'Claude fullscreen toggle' },
    { '<leader>akv', desc = 'Claude vibe mode toggle' },
    { '<leader>ai', '<cmd>ClaudeCode<cr>', desc = 'Claude toggle' },
    { '<leader>akf', '<cmd>ClaudeCodeFocus<cr>', desc = 'Claude focus' },
    { '<leader>akr', '<cmd>ClaudeCode --resume<cr>', desc = 'Claude resume' },
    { '<leader>akc', '<cmd>ClaudeCode --continue<cr>', desc = 'Claude continue' },
    { '<leader>akb', '<cmd>ClaudeCodeAdd %<cr>', desc = 'Claude add buffer' },
    { '<leader>aks', '<cmd>ClaudeCodeSend<cr>', mode = 'v', desc = 'Claude send selection' },
    { '<leader>aky', '<cmd>ClaudeCodeDiffAccept<cr>', desc = 'Claude accept diff' },
    { '<leader>akd', '<cmd>ClaudeCodeDiffDeny<cr>', desc = 'Claude deny diff' },
  },
}
