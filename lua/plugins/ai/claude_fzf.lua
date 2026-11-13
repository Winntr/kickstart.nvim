-- fzf pickers that send files/grep results to Claude Code, plus conversation history.
-- Keys live under <leader>ak* (<leader>c is the Code group).
return {
  {
    'pittcat/claude-fzf.nvim',
    dependencies = { 'ibhagwan/fzf-lua', 'coder/claudecode.nvim' },
    -- Pinned: upstream doc/ has duplicate help tags, so lazy's :helptags step errors on every update.
    -- I deleted the plugin's doc/ dir locally; pin keeps lazy from trying to update over that.
    pin = true,
    opts = { auto_context = true, batch_size = 10 },
    keys = {
      { '<leader>akF', '<cmd>ClaudeFzfFiles<cr>', desc = 'Claude fzf files' },
      { '<leader>akg', '<cmd>ClaudeFzfGrep<cr>', desc = 'Claude fzf grep' },
      { '<leader>akB', '<cmd>ClaudeFzfBuffers<cr>', desc = 'Claude fzf buffers' },
      { '<leader>akG', '<cmd>ClaudeFzfGitFiles<cr>', desc = 'Claude fzf git files' },
      { '<leader>akD', '<cmd>ClaudeFzfDirectory<cr>', desc = 'Claude fzf directory' },
    },
    cmd = { 'ClaudeFzf', 'ClaudeFzfFiles', 'ClaudeFzfGrep', 'ClaudeFzfBuffers', 'ClaudeFzfGitFiles', 'ClaudeFzfDirectory' },
  },
  {
    'pittcat/claude-fzf-history.nvim',
    dependencies = { 'ibhagwan/fzf-lua' },
    config = function()
      require('claude-fzf-history').setup()
    end,
    keys = {
      { '<leader>akh', '<cmd>ClaudeHistory<cr>', desc = 'Claude history' },
    },
    cmd = { 'ClaudeHistory', 'ClaudeHistoryDebug' },
  },
}
