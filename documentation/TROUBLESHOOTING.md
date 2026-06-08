# Troubleshooting

## Agentic Cursor ACP on Windows

If `agentic.nvim` with `provider = 'cursor-acp'` fails with `Failed to initialize` and `{ code = -32000, message = "disconnected" }`, check how the provider process is launched.

### Required launch shape

Agentic must start Cursor in ACP stdio mode:

- `node.exe <cursor-agent>/index.js acp` on Windows, or
- `cursor-agent acp` / `agent acp` on other platforms

The `acp` subcommand is required. Launching `node.exe` with only `index.js` starts the interactive CLI and breaks ACP.

### Do not use PowerShell or `.cmd` wrappers for Agentic ACP

`agent.cmd` and `cursor-agent.ps1` are fine for interactive terminal use, but Agentic spawns the provider with libuv stdio pipes. On Windows, launching through `powershell.exe -File ... acp` or `agent.cmd acp` can exit immediately or fail to attach stdio, which produces the `disconnected` error.

This config uses `lua/custom/cursor_agent.lua` function `agentic_acp_provider()` to spawn the latest installed Cursor Agent `node.exe` directly with `index.js acp` and the wrapper env vars (`CURSOR_INVOKED_AS`, `NODE_COMPILE_CACHE`).

### Windows Terminal tab spam

If opening Agentic creates many Windows Terminal tabs, the cause is usually libuv spawning the ACP child with `detached = true`, which can allocate a new visible console per launch.

This config applies `lua/custom/patches/agentic_acp_transport.lua` before Agentic loads. It sets `hide = true` and `detached = false` for ACP provider spawns on Windows so the Cursor agent stays attached to Neovim stdio without opening console windows.

Do not point Agentic at `agent-hidden.bat` or other wrappers that use `start /b`; those can also spawn extra terminal tabs.

### Debug steps

1. Run `:checkhealth agentic`
2. Enable `debug = true` in `lua/plugins/ai/agentic.lua`
3. Reproduce once and inspect `~/.cache/nvim/agentic_debug.log`
4. Confirm `agent status` succeeds in a normal terminal
