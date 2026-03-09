# gitsigns.nvim

**Plugin:** `lewis6991/gitsigns.nvim`
**Config:** `lua/plugins/common.lua`

## When to use

Use gitsigns for **day-to-day git awareness** while editing. It shows which lines
have been added, changed, or deleted in the gutter, and lets you stage/unstage
individual hunks without leaving your buffer.

This is not a conflict resolution tool -- for that, use
[git-conflict.nvim](gitconflict.md) (inline) or [diffview.nvim](diffview.md)
(side-by-side).

## Gutter signs

| Sign | Meaning        |
| ---- | -------------- |
| `+`  | Added line     |
| `~`  | Changed line   |
| `_`  | Deleted line   |
| `~`  | Change+delete  |

## Navigation

| Key  | Action              |
| ---- | ------------------- |
| `]h` | Next hunk           |
| `[h` | Previous hunk       |

## Staging and resetting

All under `<leader>g` (git):

| Key           | Action                           |
| ------------- | -------------------------------- |
| `<leader>gs`  | Stage hunk (normal or visual)    |
| `<leader>gr`  | Reset hunk (normal or visual)    |
| `<leader>gS`  | Stage entire buffer              |
| `<leader>gR`  | Reset entire buffer              |
| `<leader>gu`  | Undo last stage hunk             |

## Preview and blame

| Key           | Action                           |
| ------------- | -------------------------------- |
| `<leader>gp`  | Preview hunk (floating window)   |
| `<leader>gi`  | Preview hunk inline              |
| `<leader>gB`  | Blame current line (full)        |

## Text objects

| Key  | Mode   | Action               |
| ---- | ------ | -------------------- |
| `ih` | o, x   | Select inside hunk   |

Use `vih` to visually select a hunk, `dih` to delete it, `cih` to change it, etc.

## Typical workflow

1. Make edits to a file
2. Gutter signs appear showing what changed
3. `]h` / `[h` to navigate between hunks
4. `<leader>gp` to preview what changed
5. `<leader>gs` to stage a hunk, `<leader>gr` to discard it
6. `<leader>gS` to stage the whole file when ready
7. `<leader>gB` to check blame if you're unsure about existing code
