## [Unreleased]

### Added
- Lazygit `G` custom command for AI-generated commit messages via `scripts/lazygit-ai-commit.ps1` (Cursor `agent -p`; scope menu for staged vs all changes; `output: terminal` for commit editor).
- Diffview keymaps under `<leader>g`: `gd` open changes, `gD` toggle, `gH` file history, `gP` vs last commit.
- `custom.msgarea` helper for closing, resetting, and routing lightweight status output through msgarea.
- `mini.pick` as the primary picker surface, routed into msgarea when available.
- Restored `which-key.nvim` with auto-discovery from `desc` keymaps plus `<leader>?` / `<leader><leader>` cheat sheets.
- Enabled `99.nvim` with a custom `CursorCliProvider` using the shared Cursor Agent CLI (`cursor_agent.print_command`) on Windows via `node.exe index.js --print`.
- Replaced `agentic.nvim` with `avante.nvim` using `cursor-acp` and shared `cursor_agent.acp_provider()` Windows spawn helpers.
- Added `blink.cmp` (pinned to `1.*`) with `blink.compat` for Avante completion sources.
- Added `custom.wtf_cursor` adapter to run wtf diagnose/fix through Cursor CLI `--print` on Windows-safe spawn paths.

### Changed
- Migrated `nvim-treesitter` and `nvim-treesitter-textobjects` to the `main` branch rewrite for Neovim 0.12 compatibility (fixes render-markdown/Avante `range` nil treesitter errors).
- Normal-mode `<Esc>` hides msgarea first, then closes hidden windows; `<leader>ms` / `<M-n>` restore collapsed msgarea for scrolling.
- `wtf.nvim` diagnose/fix status messages now route through msgarea instead of Snacks notifier toasts.
- `mini.pick` clears stale msgarea content before opening in the msgarea region.
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
- Hardened `nvim-treesitter` config to avoid startup crash when the plugin directory is missing after a failed Lazy sync.
- Guarded `render-markdown.nvim` treesitter parse during Avante streaming to avoid `range (a nil value)` crashes when parser nodes are stale.
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
