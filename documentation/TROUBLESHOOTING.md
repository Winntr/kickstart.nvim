# Troubleshooting

## Agentic Cursor ACP on Windows

Deprecated: `agentic.nvim` is disabled. Use `avante.nvim` with `provider = "cursor-acp"` instead. The spawn notes below still apply to Avante's ACP client.

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

### Debug steps

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

## blink.cmp and copilot.lua coexistence

This config uses:

- `blink.cmp` for popup completion (`Tab`, `S-Tab`, `CR`)
- `copilot.lua` for inline ghost text (`<C-y>` accept)

`vim.g.ai_cmp = false` in `lua/config/options.lua` prevents Copilot from trying
to own completion menu behavior.

`lua/plugins/blink.lua` also toggles `vim.b.copilot_suggestion_hidden` on
`BlinkCmpMenuOpen` and `BlinkCmpMenuClose` so ghost text and menu do not fight.

If `<C-y>` confirms a menu item instead of accepting Copilot text, check blink
keymaps and make sure `<C-y>` is not mapped to `select_and_accept`.

## Wilder on Windows

`wilder.nvim` is enabled and falls back to `wilder.vim_fuzzy_filter()` on
Windows (where `fzy-lua-native` is not built). If the popup fails to render:

1. Run `:checkhealth` and confirm no UI ext errors.
2. Test `:` and `/` modes directly after startup.
3. Temporarily disable msgarea routing to isolate cmdline UI conflicts.

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
