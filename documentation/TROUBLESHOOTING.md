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
