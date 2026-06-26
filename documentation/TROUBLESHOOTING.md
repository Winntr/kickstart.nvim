# Troubleshooting

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

## Cursor Agent terminal (neovim-cursor)

Primary AI agent workflow: `felixcuello/neovim-cursor` runs `cursor agent` in a Neovim split terminal (no ACP stdio).

### Keymaps

| Key | Mode | Action |
|-----|------|--------|
| `<leader>aa` | Normal | Toggle Cursor agent terminal |
| `<leader>aa` | Visual | Show agent and send selection as `@file:lines` (does not hide an open agent) |
| `<leader>as` | Visual | Send selection to agent (`@file:lines`) |
| `<leader>ac` | Normal | Send current file to agent (`@file`) |
| `<leader>aB` | Normal | Send all named open buffers to agent (one `@file` per line) |
| `<leader>af` | Normal | Focus/show agent terminal |
| `<leader>an` | Normal | Create new agent terminal |
| `<leader>at` | Normal | Select agent terminal (fuzzy picker; `vim.ui.select` fallback without Telescope) |
| `<leader>ar` | Normal | Rename active agent terminal |

Context is sent as Cursor `@` references (file path with optional line range), not inline buffer text. Unsaved buffers with no path are skipped with a warning; save the file first.

Implementation: `lua/custom/cursor_chat.lua` (wired from `lua/plugins/ai/neovim_cursor.lua`).

### Commands

- `:CursorAgent` — toggle agent terminal
- `:CursorAgentNew [prompt]` — new agent session
- `:CursorAgentSelect` — picker
- `:CursorAgentRename [name]` — rename
- `:CursorAgentList` — list sessions

### If the terminal does not open

1. Confirm `cursor` (non-Windows) or `agent` (Windows) is on PATH.
2. Run `agent` (Windows) or `cursor agent` (other platforms) in a normal terminal and verify it starts.
3. Run `:Lazy sync` to install `felixcuello/neovim-cursor`.
4. Check `:messages` for spawn errors.

### Esc in the agent terminal

`neovim-cursor` maps single `<Esc>` to hide the split, which blocks Cursor CLI shortcuts
and conflicts with double-Esc terminal normal mode. This config patches agent buffers in
`lua/custom/cursor_terminal_esc.lua`:

| Key | Mode | Action |
|-----|------|--------|
| `<Esc>` | Terminal insert | Sent to the agent CLI |
| `<Esc><Esc>` | Terminal insert | Neovim normal mode in the split |
| `<Esc><Esc>` | Normal (in split) | Hide the agent window |
| `<leader>aa` | Normal | Toggle agent |
| `<leader>aa` | Visual | Send selection to agent (show-only) |

Reopen the agent (`<leader>aa`) after updating this config so existing buffers pick up the patch.

### Legacy: Avante Cursor ACP

`avante.nvim` is disabled (`enabled = false` in `lua/plugins/ai/avante.lua`). Notes below are kept for reference if you re-enable ACP.

## Agentic Cursor ACP on Windows (legacy)

Deprecated: `agentic.nvim` is disabled. `avante.nvim` Cursor ACP is also disabled; use `neovim-cursor` above. Spawn notes below apply only if you re-enable an ACP client.

If Avante with `provider = 'cursor-acp'` fails with `Failed to initialize` and `{ code = -32000, message = "disconnected" }`, check how the provider process is launched.

### Required launch shape

Agentic must start Cursor in ACP stdio mode (Avante uses the same shape):

- `node.exe <cursor-agent>/index.js acp` on Windows, or
- `cursor-agent acp` / `agent acp` on other platforms

The `acp` subcommand is required. Launching `node.exe` with only `index.js` starts the interactive CLI and breaks ACP.

### Do not use PowerShell or `.cmd` wrappers for Agentic ACP

`agent.cmd` and `cursor-agent.ps1` are fine for interactive terminal use, but Agentic spawns the provider with libuv stdio pipes. On Windows, launching through `powershell.exe -File ... acp` or `agent.cmd acp` can exit immediately or fail to attach stdio, which produces the `disconnected` error.

This config uses `lua/custom/cursor_agent.lua` function `acp_provider()` to spawn the latest installed Cursor Agent `node.exe` directly with `index.js acp` and the wrapper env vars (`CURSOR_INVOKED_AS`, `NODE_COMPILE_CACHE`).

### Windows Terminal tab spam

If opening Agentic creates many Windows Terminal tabs, the cause is usually libuv spawning the ACP child with `detached = true`, which can allocate a new visible console per launch.

This config applies `lua/custom/patches/agentic_acp_transport.lua` before Avante loads. It sets `hide = true` and `detached = false` for ACP provider spawns on Windows so the Cursor agent stays attached to Neovim stdio without opening console windows.

Do not point Avante at `agent-hidden.bat` or other wrappers that use `start /b`; those can also spawn extra terminal tabs.

### Debug steps (legacy ACP)

1. Run `:AvanteToggle` or `<leader>at` and send a short prompt
2. Run `:checkhealth` and confirm `cursor-agent` / `agent` is on PATH
3. Confirm `agent status` succeeds in a normal terminal
4. Use `<leader>aM` / `<leader>am` to switch ACP model/mode after the sidebar is open (config auto-opens it if needed)

### ACP model/mode keybind errors

If `<leader>aM` or `<leader>am` errors with `attempt to index field 'result' (a nil value)` in `sidebar.lua`, the sidebar object existed but was not rendered. This config patches `avante.acp_config_selector` in `lua/custom/patches/avante_acp_selector.lua` to call `sidebar:open({})` first.

If you see `No model options available from cursor-acp ACP agent`, Cursor's ACP server often returns empty `configOptions` (a known Cursor CLI limitation). This config falls back to `cursor-agent models` for `<leader>aM` and static Agent/Plan/Ask modes for `<leader>am`. Runtime model switching may still fail; the default model is set at ACP startup with `--model composer-2.5` in `lua/plugins/ai/avante.lua`.

## 99.nvim with Cursor CLI on Windows

99 uses Cursor Agent in **`--print` subprocess mode**, not stdio ACP. Agentic uses **`acp`** on the same binary. Both share `lua/custom/cursor_agent.lua` for spawning.

On Windows, 99 spawns `node.exe <cursor-agent>/index.js --trust --force --model <id> --print <prompt>`. Do not route this through `agent.cmd` or PowerShell wrappers; redirection can truncate prompts.

`lua/custom/patches/99.lua` registers `CursorCliProvider` with stdout fallback when the model does not write to 99's temp file.

### Keymaps

| Key | Action |
|-----|--------|
| `<leader>9v` | Visual selection edit (visual mode) |
| `<leader>9s` | 99 search |
| `<leader>9x` | Cancel in-flight requests |
| `<leader>9m` | Select model |

Default model: `composer-2.5` (`cursor_agent.MODEL_COMPOSER_25`).

## wtf.nvim with Cursor CLI

`wtf.nvim` diagnose/fix commands use `lua/custom/wtf_cursor.lua`, which shells out
to `cursor-agent --print` through `cursor_agent.print_command()` and uses the same
Windows-safe `node.exe index.js` spawn path as `99.nvim`.

The wtf plugin itself is configured with a built-in provider (`ollama`) only for
history/search UI validation. AI diagnose/fix do not use wtf's HTTP client.

### Why this is `--print` and not ACP

`wtf.nvim`'s upstream client is request/response and provider-based. ACP is a
long-lived stdio protocol intended for agent sessions (used by Avante). For
single diagnostic explain/fix prompts, `--print` is the correct transport.

### If `wtf` returns empty output or fails

1. Confirm `agent status` works in a terminal.
2. Confirm `cursor-agent models` returns at least one model.
3. Verify `<leader>awd` / `<leader>awf` call `custom.wtf_cursor` (not `wtf.diagnose` directly).
4. Check Neovim messages for stderr from the Cursor CLI subprocess.

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
