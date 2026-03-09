# diffview.nvim

**Plugin:** `sindrets/diffview.nvim`
**Config:** `lua/plugins/git.lua`

## When to use

Use diffview for **complex conflicts** where you need full context -- seeing the
base (common ancestor), your branch, and the incoming branch side by side. Also
useful for reviewing staged changes and browsing file history.

This is the heavy-duty tool. If you just need to pick "ours" or "theirs" on a
simple conflict, use [git-conflict.nvim](gitconflict.md) instead.

## Keybindings

All under `<leader>gd` (git diff):

| Key            | Action                           |
| -------------- | -------------------------------- |
| `<leader>gdo`  | Open diffview                    |
| `<leader>gdc`  | Close diffview                   |
| `<leader>gdf`  | File history (current file)      |
| `<leader>gdh`  | File history (all files)         |
| `<leader>gds`  | Staged changes                   |

### Inside diffview (merge tool)

| Key          | Action                                    |
| ------------ | ----------------------------------------- |
| `<leader>co` | Choose ours (current branch)              |
| `<leader>ct` | Choose theirs (incoming branch)           |
| `<leader>cb` | Choose base (common ancestor)             |
| `<leader>ca` | Choose all (keep both)                    |
| `dx`         | Delete conflict region                    |
| `ga`         | Stage / unstage entry (file panel)        |
| `gA`         | Stage all                                 |
| `gU`         | Unstage all                               |

## Layout

The merge tool uses `diff3_horizontal` layout -- three horizontal panes showing
LOCAL (yours), BASE (ancestor), and REMOTE (theirs). The merged result is in the
center pane where you make edits.

## Typical workflow

1. You're in a merge/rebase with conflicts
2. `:DiffviewOpen` or `<leader>gdo`
3. Navigate the file panel to pick a conflicted file
4. Compare all three versions side by side
5. Use `<leader>co`, `<leader>ct`, etc. to resolve in the merge pane
6. `ga` to stage when done, move to next file
7. `<leader>gdc` to close when all files are resolved

## Commands

| Command                | Description                      |
| ---------------------- | -------------------------------- |
| `:DiffviewOpen`        | Open diff view (detects merge)   |
| `:DiffviewClose`       | Close diff view                  |
| `:DiffviewToggle`      | Toggle diff view                 |
| `:DiffviewFileHistory` | Browse file history              |
