# git-conflict.nvim

**Plugin:** `akinsho/git-conflict.nvim`
**Config:** `lua/plugins/git.lua`

## When to use

Use git-conflict for **quick, inline conflict resolution** directly in your
buffer. It highlights conflict markers, lets you pick a side with a single
keystroke, and moves on. No separate view needed.

For complex conflicts where you need to compare all three versions (ours, base,
theirs) side by side, use [diffview.nvim](diffview.md) instead.

## Inline keybindings (no leader)

These work directly on a conflict marker in any buffer:

| Key  | Action                           |
| ---- | -------------------------------- |
| `co` | Choose ours (current branch)     |
| `ct` | Choose theirs (incoming branch)  |
| `cb` | Choose both (keep all)           |
| `c0` | Choose none (delete conflict)    |
| `]x` | Jump to next conflict            |
| `[x` | Jump to previous conflict        |

## Leader keybindings

All under `<leader>gc` (git conflict):

| Key            | Action                           |
| -------------- | -------------------------------- |
| `<leader>gcr`  | Refresh conflict detection       |
| `<leader>gcl`  | List all conflicts in quickfix   |
| `<leader>gco`  | Choose ours                      |
| `<leader>gct`  | Choose theirs                    |
| `<leader>gcb`  | Choose both                      |
| `<leader>gcn`  | Choose none                      |
| `<leader>gc0`  | Choose base (common ancestor)    |

## Typical workflow

1. Open a file with conflicts -- markers are auto-highlighted
2. `]x` to jump to first conflict
3. Read the conflict, pick a side: `co`, `ct`, `cb`, or `c0`
4. `]x` to jump to next conflict, repeat
5. `<leader>gcl` to see all remaining conflicts across files in the quickfix list
6. Work through the quickfix list until clean

## Tips

- **Diagnostics are auto-disabled** in conflicted files to reduce noise
- Use `<leader>gcr` to re-scan if conflict markers aren't detected
- The quickfix list (`<leader>gcl`) is great for getting an overview of how many
  conflicts remain across the entire project
- For the best experience, set diff3 conflict style in git:
  ```bash
  git config --global merge.conflictstyle diff3
  ```
  This shows the BASE (common ancestor) in conflict markers, giving you more
  context for making decisions.

## Commands

| Command                    | Description                          |
| -------------------------- | ------------------------------------ |
| `:GitConflictChooseOurs`   | Accept current branch changes        |
| `:GitConflictChooseTheirs` | Accept incoming branch changes       |
| `:GitConflictChooseBoth`   | Keep both changes                    |
| `:GitConflictChooseBase`   | Revert to common ancestor            |
| `:GitConflictChooseNone`   | Delete the conflict region           |
| `:GitConflictListQf`       | List all conflicts in quickfix       |
| `:GitConflictRefresh`      | Re-detect conflicts in buffer        |
