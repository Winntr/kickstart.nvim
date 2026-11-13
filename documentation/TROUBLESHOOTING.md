# Troubleshooting

## Startup error: `Invalid plugin spec` for DataGrip

If Neovim fails in `init.lua` and the error block mentions `DataGrip`,
`DataGripFile`, or `DataGripProject`, the cause is a lazy.nvim validation
error: those SQL/DataGrip helpers are normal config, not a real plugin spec.

Expected state in this config:

- `init.lua` loads `lua/config/sql.lua`
- `lua/plugins/sql.lua` returns an empty spec list

Quick verification:

```powershell
nvim --headless -c "qa"
```

That command should exit cleanly with no `Invalid plugin spec` output.

## Workspace task panel (`custom.tasks` + `custom.tasks_ui`)

Overseer-style bottom panel built with **nui.nvim** (rounded borders, tree task list, live output pane). Processes use PTY buffers displayed in the output split.

### Open the panel

| Key | Action |
|-----|--------|
| `<leader>tm` | Toggle task panel |
| `<leader>tv` | Open task panel |
| `:TaskUI` | Toggle task panel |

### Panel layout

- **Shell** (optional, above tasks): interactive `$SHELL` in project root — `T` or `<leader>tT`
- **Tasks** (middle): `nui.tree` list with status icons and command
- **Output** (bottom): live terminal buffer for the selected task

● running  ◐ stopped  ○ not started

Footer on the task list shows keybindings.

### List keymaps

| Key | Action |
|-----|--------|
| `r` | Run selected task |
| `s` | Stop (Ctrl+C; answer y/n in output) |
| `x` | Kill |
| `R` | Restart |
| `T` | Toggle shell above panel |
| `i` | Interact (focus output, terminal mode) |
| `<CR>` | State-aware action menu (Run, Show, Stop, Restart, Kill, etc.) |
| `a` | Add task |
| `e` | Edit `.nvim/tasks.lua` |
| `q` / `<Esc>` | Close panel (processes keep running) |

### Global shortcuts

| Key | Action |
|-----|--------|
| `<leader>tr` | Open panel or run selected task |
| `<leader>ts` | Stop current/selected task |
| `<leader>tK` | Kill current/selected task |
| `<leader>th` / `<leader>tH` | Close task panel |
| `<leader>ta` | Add task |
| `<leader>tT` | Toggle shell above task panel |

### Workspace file

Tasks are stored at `<project_root>/.nvim/tasks.lua`:

```lua
---@type WorkspaceTask[]
return {
  { name = "dev", cmd = "just dev" },
}
```

### Commands

- `:TaskRun [name]` — run task (opens panel if needed)
- `:TaskShow [name]` — show output in panel
- `:TaskStop [name]` — stop with interactive prompts in output pane
- `:TaskKill [name]` — force kill
- `:TaskHide` — close panel
- `:TaskAdd` — add task interactively
- `:TaskTerminal` — toggle shell above task panel

Implementation: `lua/custom/tasks.lua`, `lua/custom/tasks_ui.lua` (nui.nvim).

## Claude Code (claudecode.nvim, 99.nvim, wtf.nvim, lazygit)

All AI features use the `claude` CLI (must be on PATH and logged in).

| Feature | Implementation |
|---|---|
| Interactive agent | `coder/claudecode.nvim` (`lua/plugins/ai/claudecode.lua`): `<leader>ai` toggle, `<leader>ak{f,r,c,b,s,y,d}` focus/resume/continue/add buffer/send selection/accept diff/deny diff |
| 99.nvim (`<leader>9*`) | Built-in `ClaudeCodeProvider` (`claude --print`); model via `$CLAUDE_99_MODEL` (default `claude-sonnet-5-5`) |
| wtf.nvim diagnose/fix (`<leader>awd`/`awf`) | `lua/custom/wtf_claude.lua`; model via `$WTF_CLAUDE_MODEL` (default `sonnet`) |
| Lazygit `G` AI commit | `scripts/lazygit-ai-commit.ps1`; model via `$CLAUDE_COMMIT_MODEL` (default `haiku`) |

If something fails, run `claude --print "hello"` in a terminal first. 99's `ClaudeCodeProvider` passes `--dangerously-skip-permissions`.

## Mermaid diagrams in markdown

Cursor and other tools often emit ` ```mermaid ` fenced blocks. This config renders them three ways:

| Method | When | Requirements |
|--------|------|----------------|
| **Browser preview** | `<leader>um` on a fence | None (built-in HTTP server + mermaid.js) |
| **Terminal inline** | `<leader>uM` on a fence | `mmdc` + Kitty **or** `chafa` |
| **Auto inline in buffer** | Open markdown | `mmdc` + ImageMagick `magick` + Kitty/WezTerm/Ghostty |

`render-markdown.nvim` leaves `mermaid` fences alone (`code.disable`) so Snacks Image can detect them.

### Keymaps (markdown / Avante buffers)

| Key | Action |
|-----|--------|
| `<leader>um` | Live browser preview for ```mermaid block at cursor |
| `<leader>uM` | Inline terminal render for block at cursor |

Commands: `:MermaidBlockPreview`, `:MermaidBlockRender`, `:MermaidPreview`, `:MermaidPreviewStop`.

### Windows Terminal note

Snacks Image uses the **Kitty graphics protocol**. Windows Terminal does **not** support Kitty graphics (Sixel is separate). On WT, use **`<leader>um`** (browser preview) — no extra installs.

For in-editor graphics, use **WezTerm** or **Ghostty**, or install **chafa** and use `<leader>uM`.

### Optional tools (inline / auto render)

```powershell
npm install -g @mermaid-js/mermaid-cli
winget install ImageMagick.ImageMagick
scoop install chafa   # optional; ASCII/color inline in any terminal
```

Verify: `:checkhealth snacks` (image section), `mmdc --version`, `magick -version`.

Implementation: `lua/plugins/mermaid.lua`, `lua/custom/mermaid_markdown.lua`, `lua/plugins/snacks.lua` (`image`), `lua/plugins/ui.lua` (`render-markdown`).

### Legacy: Avante Cursor ACP

`avante.nvim` is disabled (`enabled = false` in `lua/plugins/ai/avante.lua`). Notes below are kept for reference if you re-enable ACP.

## Trouble workspace diagnostics empty

You do **not** need every file open in a buffer. Workspace-wide diagnostics come from the LSP analyzing the project and Neovim storing results (often on hidden/unloaded buffers).

This config uses:

- basedpyright `diagnosticMode = 'workspace'` (analyze the whole project, not just open files)
- `init_options.disablePullDiagnostics = true` (basedpyright + Neovim pull diagnostics are unreliable without this)
- `<leader>xx` calls `vim.lsp.buf.workspace_diagnostics()` then opens Trouble after diagnostics stream in

If workspace still shows no items:

1. Open any file in the project so basedpyright attaches, then wait a few seconds for the workspace scan.
2. Confirm counts: `:lua vim.print('buffer', #vim.diagnostic.get(0), 'all', #vim.diagnostic.get(nil))`
3. Restart LSP: `:LspRestart basedpyright` (required after `disablePullDiagnostics` if the server was already running).
4. Large repos can take 10–30+ seconds on first scan; press `<leader>xx` again after waiting.

Buffer-only view: `<leader>xX` (`setloclist` + Trouble `loclist`).

## blink.cmp and copilot.lua coexistence

This config uses:

- `blink.cmp` for popup completion (see keymap table below)
- `copilot.lua` for inline ghost text (`<C-y>` accept)
- `blink-emoji.nvim` for `:name` emoji completion in insert mode (replaces legacy `cmp-emoji`)

### blink completion keys (insert mode)

| Key | Action |
|-----|--------|
| `:` then name (e.g. `:smile`) | Open emoji menu |
| **Tab** | Accept selected item (or first match); falls back to snippet tab stops |
| **Ctrl-Enter** | Accept highlighted completion item (menu must be open) |
| **Enter** | New line (normal insert behavior) |
| **↑ / ↓** | Previous / next item (live preview with auto-insert) |
| **Ctrl-Space** | Open completion menu manually |
| **Ctrl-e** | Cancel / undo auto-insert preview |

**Ctrl-y** is reserved for Copilot, not blink.

`lua/plugins/blink.lua` uses the `super-tab` preset; **Ctrl-Enter** accepts when the menu is open (Enter stays newline).

## Wilder on Windows

`wilder.nvim` is enabled and falls back to `wilder.vim_fuzzy_filter()` on
Windows (where `fzy-lua-native` is not built).

Devicons in the Wilder popup are intentionally disabled in
`lua/plugins/wilder.lua`. The upstream `wilder.popupmenu_devicons()` Vimscript
component can fail with `E704: Funcref variable name must start with a capital:
l:expand` on this Neovim setup, which breaks popup rendering (`E714: List
required`, `E121: Undefined variable: l:lines`).

If the popup still fails to render:

1. Run `:checkhealth` and confirm no UI ext errors.
2. Test `:` and `/` modes directly after startup.
3. Temporarily disable msgarea routing to isolate cmdline UI conflicts.

## LSP (Neovim 0.12 native API)

Inspect LSP with `:LspInfo` (alias for `:checkhealth vim.lsp`).

### Mason install fails (npm / pip / basedpyright)

PyPI installs need **`%APPDATA%\pip\pip.ini`** with Artifactory credentials. Use your **JFrog username** (not the npm `email=` field) with your identity or API token. Mason is wired in `lua/config/artifactory.lua`; see `documentation/ARTIFACTORY.md`.

npm installs use `%USERPROFILE%\.npmrc`. If PyPI works in a test venv but Mason fails, ensure Mason is not overriding auth: this config avoids a credential-less `--index-url` unless `ARTIFACTORY_PYPI_INDEX_URL` is set.

For GitHub-only packages (`gopls`, `lua-language-server`), fix GitHub access or a release mirror — not only npm/PyPI.

### basedpyright still runs after removing Mason package

Mason only manages binaries under `nvim-data/mason/`. This config also enables
`basedpyright` via `vim.lsp.enable('basedpyright')` in `lua/plugins/lsp.lua`.
If `basedpyright-langserver` is on PATH (for example `~/.local/bin` from pip or
pipx), Neovim will still start it after a Mason uninstall.

To disable basedpyright entirely:

```vim
:lua vim.lsp.enable('basedpyright', false)
```

Or remove `basedpyright` from the `servers` list in `lua/plugins/lsp.lua`.

### Python imports not resolving

basedpyright must use the project virtualenv, not a global `python3` on PATH.
On attach, this config sets `python.pythonPath` when `.venv` or `venv` exists
under the LSP root directory.

After changing LSP settings, restart the client from a Python buffer:

```vim
:lua vim.lsp.stop_client(vim.lsp.get_clients({name='basedpyright'})[1].id, true)
```

Then reopen the file or run `:edit` to reattach.

Manual override (per buffer session):

```vim
:LspPyrightSetPythonPath C:/path/to/project/.venv/Scripts/python.exe
```

### LSP log file is huge

`:checkhealth vim.lsp` reports log size at `stdpath('data')/lsp.log`. Delete or
truncate that file if it grows large; optionally lower verbosity with
`:lua vim.lsp.set_log_level('warn')`.

## Msgarea dismiss and reset

Sticky msgarea content can be dismissed or restored with. All msgarea bindings use the `<leader>m` prefix (`<leader>m` opens the which-key submenu):

| Key / command | Action |
|---------------|--------|
| `<Esc>` (normal mode) | Hide visible msgarea, else close hidden windows, else clear search highlights |
| `<M-n>` (`Alt+n`) | Toggle msgarea show/hide (non-destructive) |
| `<leader>ms` | Show/expand msgarea and focus it for scrolling |
| `<leader>mt` | Toggle msgarea show/hide |
| `<leader>mc` | Close all msgarea windows |
| `:MsgareaShow` | Expand and focus msgarea |
| `:MsgareaToggle` | Toggle msgarea visibility |
| `:MsgareaClose` | Close all msgarea windows |

Clicking back into the editor collapses msgarea without destroying it. Use `<leader>ms` or `<M-n>` to bring it back and scroll with `j`/`k` while focused.

`lua/custom/msgarea.lua` centralizes close/reset helpers. Local flows that reclaim the msgarea region call `reset()` before opening:

- `mini.pick` pickers (`<leader>ff`, `<leader>fg`, etc.)
- `mini.extra` pickers: `<leader>f.` recent files, `<leader>fd` document symbols, `<leader>fk` keymaps, `<leader>fl` breadcrumbs, `<leader>fs` workspace symbols, `<leader>fo` outline, `<leader>sd` diagnostics, `<leader>sw` grep word, `<leader>gh` git hunks, `<leader>cr/ci/ct` LSP pickers
- Quickfix/loclist: `<leader>ql` toggle loclist, `<leader>qd` diagnostics to loclist, `]q`/`[q` next/prev quickfix item
- Diagnostics: `<leader>xf` float popup for current line, `<leader>xx`/`xX` Trouble, `<leader>sd` picker
- Utilities: `<leader>y` yank file path, `<leader>cl` toggle cursor line, `<leader>xt` project TODOs, `<leader>vu` undotree, `<leader>vr` / `:UsageReport` usage stats
- `wtf.nvim` diagnose/fix via `custom.wtf_cursor` (`<leader>awd`, `<leader>awf`)

Lightweight `wtf` status output (start, success, warnings, errors) is routed through msgarea via ui2 message targets. Multi-line diagnose responses still open in the `wtf` popup.

## Avante / render-markdown treesitter errors

If Avante or markdown rendering errors with:

```
attempt to call method 'range' (a nil value)
```

in `vim/treesitter.lua` via `nvim-treesitter/query_predicates.lua` and `render-markdown.nvim`, the usual cause is the archived `nvim-treesitter` **master** branch on Neovim 0.12. This config uses the **main** branch rewrite.

### Fix steps

1. **Close every Neovim instance** (the old plugin `.so` files stay locked while Neovim is open).
2. In Lazy (`:Lazy`), find `nvim-treesitter`, press `x` to remove the old install, then run `:Lazy update`.
3. Confirm `tree-sitter-cli` is on PATH (`tree-sitter --version`).
4. Run `:TSUpdate` to rebuild parsers for the new plugin.
5. Restart Neovim and reopen the Avante sidebar.

If errors persist after migration, run `:checkhealth render-markdown` and confirm markdown parsers are installed.

This config also patches `render-markdown` to skip a render pass when treesitter parse fails on a streaming buffer (common while Avante is still writing output). That stops the error spam, but you still need the `main` branch install for full markdown rendering.

## Go syntax highlighting

Go highlighting was omitted from the nvim-treesitter `main` branch parser list during the Neovim 0.12 migration. This config installs `go`, `gomod`, `gosum`, and `gowork` parsers and starts treesitter with explicit `(buf, lang)` args.

| Filetype | Parser | Notes |
|----------|--------|-------|
| `go` | `go` | Treesitter only |
| `gomod` | `gomod` | Treesitter + `vim.bo.syntax = on` (partial query coverage) |
| `gosum` | `gosum` | Treesitter + legacy syntax |
| `gowork` | `gowork` | Treesitter + legacy syntax |

### Fix steps

1. Restart Neovim (auto-installs missing parsers on startup).
2. Or run manually: `:TSInstall go gomod gosum gowork`
3. Confirm: `:TSInstallInfo` lists all four as installed.
4. Open a `.go` file and run `:Inspect` — should show treesitter captures (e.g. `@function`).

### Parser install fails on Windows

The `main` branch builds parsers via `tree-sitter-cli` and a C compiler:

- `tree-sitter --version` must work on PATH.
- If `:TSInstall go` fails with `cl.exe` errors, install [Build Tools for Visual Studio](https://visualstudio.microsoft.com/downloads/#build-tools-for-visual-studio-2022) (Desktop development with C++).

### Go LSP (gopls) / import completion

Go completion (imports, symbols, Bubble Tea APIs) requires **gopls**, not treesitter alone.

1. Ensure `go` is on PATH (`go version`).
2. Run `:Mason` and confirm `gopls` is installed (or `:MasonInstall gopls`).
3. Open a file inside a module root (`go.mod` or `go.work` parent directory).
4. Run `:LspInfo` or `:checkhealth vim.lsp` in `main.go` — should show `gopls` attached.
5. Run `go mod download` in the project if deps are missing from the module cache.

If gopls attaches but imports still fail, run `:LspRestart` or `:lsp restart gopls` after `go mod tidy`.

### LSP commands (Neovim 0.12)

Neovim 0.12 removed the old `:LspInfo` / `:LspRestart` built-ins. This config restores them as aliases:

| Command | Native equivalent |
|---------|-------------------|
| `:LspInfo` | `:checkhealth vim.lsp` |
| `:LspRestart` | `:lsp restart` (optional server name) |
| `:LspLog` | Opens `stdpath('state')/lsp.log` |

You can also type `:lsp restart gopls` or `:checkhealth vim.lsp` directly.
