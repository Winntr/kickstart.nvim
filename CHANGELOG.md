## [Unreleased]

### Added
- [`msgarea.nvim`](https://github.com/edisj/msgarea.nvim) integration with Neovim ui2 message routing for sticky errors, shell output, and cmdline-style flows (requires Neovim 0.12+).
- `mini.pick` as the primary picker surface, routed into msgarea when available.
- Restored `which-key.nvim` with auto-discovery from `desc` keymaps plus `<leader>?` / `<leader><leader>` cheat sheets.
- Enabled `99.nvim` with a custom `CursorCliProvider` using the shared Cursor Agent CLI (`cursor_agent.print_command`) on Windows via `node.exe index.js --print`.
- Replaced `agentic.nvim` with `avante.nvim` using `cursor-acp` and shared `cursor_agent.acp_provider()` Windows spawn helpers.
- Added `blink.cmp` (pinned to `1.*`) with `blink.compat` for Avante completion sources.
- Added `custom.wtf_cursor` adapter to run wtf diagnose/fix through Cursor CLI `--print` on Windows-safe spawn paths.

### Changed
- Refactored startup into thin `init.lua` plus `lua/config/{options,global,autocommands,keymap}.lua`.
- Migrated LSP setup to native `vim.lsp.config()` / `vim.lsp.enable()` for Neovim 0.12.
- Replaced Telescope-first navigation with `mini.pick`; Snacks now covers terminal, lazygit, notifier, and statuscolumn only.
- Aggressively reduced default keymaps; trimmed `which-key.nvim` to group labels only (no manual keymap tree).
- Disabled overlapping AI plugins by default (`codecompanion`, `wtf`, `agentic`); kept Copilot, Avante (Cursor ACP), and 99 (Cursor CLI `--print`).
- Pruned unused colorscheme specs; Kanagawa remains the active theme.
- Updated `agentic.nvim` Windows `cursor-acp` startup to use `custom.cursor_agent.agentic_acp_provider()`, spawning Cursor Agent `node.exe` directly with the `acp` subcommand instead of PowerShell or `.cmd` wrappers.
- Migrated completion from `nvim-cmp` to `blink.cmp` and kept `copilot.lua` as the inline ghost-text provider.
- Enabled `wtf.nvim` with `picker = 'snacks'` and a Cursor-backed provider.
- Re-enabled `wilder.nvim` command-line/search UI with `vim_fuzzy_filter` fallback on Windows.

### Fixed
- Corrected `vim.opt.expandtab` (was incorrectly assigned to `vim.expandtab`).
- Fixed `msgarea.nvim` startup crash by enabling Neovim ui2 in `config/ui2.lua` before lazy.nvim loads the plugin (ui2 `msg` must exist when `plugin/msgarea.lua` patches `msg_show`).
- Replaced deprecated `vim.highlight.on_yank()` with `vim.hl.on_yank()`.
- Replaced legacy `vim.loop` fallbacks with `vim.uv` in custom Windows spawn helpers.
- Updated Treesitter lazy spec to use `build = ':TSUpdate'`.
- Fixed Agentic Cursor ACP initialization failures on Windows (`disconnected` / `-32000`) caused by wrapper processes exiting before stdio ACP transport attached.
- Fixed Windows Terminal tab spam when opening Agentic by patching ACP spawns to use hidden, non-detached console creation on Windows.
- Fixed a Windows launch regression where Agentic used Cursor's internal `node.exe` entrypoint without the required `acp` subcommand, which could start the interactive CLI and spawn extra terminal tabs.
- Fixed Mason startup error `Cannot find package "c3"` by excluding the custom C3 LSP from `mason-tool-installer` and using Mason registry package names for tool installation.
- Fixed Avante `<leader>aM` / `<leader>am` crashes when the sidebar was not open by patching `acp_config_selector` to open the sidebar before ACP config selection.
- Fixed Avante `Config.windows` nil crash by calling `require('avante').setup(opts)` from the lazy `config` hook (custom `config` disables lazy's auto-setup).
- Registered Avante keymaps via lazy.nvim `keys` with `desc` so which-key discovers the `<leader>a` menu.
- Fixed `No model options available from cursor-acp ACP agent` by falling back to `cursor-agent models` for `<leader>aM` and static Agent/Plan/Ask modes for `<leader>am` when Cursor ACP returns empty `configOptions`.

### Removed
- C3 language support (LSP config, treesitter parser, filetypes, and custom highlight queries).
- `mason-lspconfig.nvim` (redundant with Neovim 0.12 native `vim.lsp.config()` / `vim.lsp.enable()`).
- Default `agentic.nvim` chat UI (replaced by `avante.nvim`).
- Default `nvim-telescope/telescope.nvim` stack and `misc.pickers` Telescope/Snacks fallback layer.
- `nvim-cmp` and companion sources (`cmp-*`, `copilot-cmp`, `lspkind-nvim`, `otter.nvim`) in favor of `blink.cmp`.
- Default `agentic.nvim`, `codecompanion.nvim`, and `profile.nvim` specs from plugin import paths.
- `nvim-autopairs` after moving to blink-based completion flow.
