## [Unreleased]

### Added
- DataGrip launcher for SQL execution (`custom.datagrip`, `<leader>Dg`/`Dt` open file, `<leader>Dp` open Main project). Uses existing JDBC drivers and data sources — no driver hijacking. Removed Harlequin integration.

### Removed

### Fixed
- Harpoon menu now opens via `mini.pick` (`<leader>hh`); added `<leader>hs1-4` to assign slots, `<leader>hp`/`hn` prev/next, and feedback when jumping to empty slots.
- Restored filepath breadcrumbs: lualine `short_path` / `truncated_path` in the statusline and dropbar winbar via explicit `opts = {}` so lazy.nvim calls `setup()` on load.
- Cursor done notifications: acknowledge now suppresses repeat alerts; defer while agent split focused; alert on WinLeave/TermLeave; detect all agent tabs; single Windows toast (no duplicate vim.notify).
- Go LSP: enable `gopls`; restore `:LspInfo` / `:LspRestart` / `:LspLog` aliases for Neovim 0.12 (`:checkhealth vim.lsp`, `:lsp restart`).
- Go treesitter highlighting: add `go`, `gomod`, `gosum`, `gowork` parsers to install list; FileType autocmd passes explicit `(buf, lang)` and enables legacy syntax for `go.mod` / `go.sum` / `go.work`.
- Task add prompt crash: nui `Input` unmounts before `on_submit`; removed redundant `unmount()` and fixed callback closure over the input instance.
- Task panel crash on open: nui tree nodes expose fields on the node directly (`node.id`), not `node.data`.
- Task panel toggle after hide: nui clears split `winid` when hidden; `is_open()` now guards before `nvim_win_is_valid`.

### Added
- `laytan/cloak.nvim` masks secret values in `.env*` files (default `=.+` pattern); Telescope preview cloaking enabled.
- `<leader>xf` shows line diagnostics in a floating window (wraps; avoids clipped inline virtual text).
- Expanded find/search/code keymaps via `mini.extra` pickers: `<leader>f.` recent files, `<leader>fd` document symbols, `<leader>fk` keymap search, `<leader>fl` symbol breadcrumbs (moved from `<leader>ls`), `<leader>sd` diagnostics, `<leader>sw` grep word, `<leader>xt` TODOs, `<leader>gh` git hunks, `<leader>cr/ci/ct` LSP pickers, `<leader>cl` cursor line, `<leader>y` yank path, `<leader>ql` loclist toggle, `<leader>qd` diagnostics to loclist, `]q`/`[q` quickfix nav, `<leader>vu` undotree, `<leader>vr` usage report.
- `custom.usage` tracks keymap/plugin/command usage to `usage.json`; `:UsageReport` and `:UsageReset`.
- `<leader>fs` workspace symbol search via `mini.extra` LSP picker (`workspace_symbol_live`).
- `<leader>fo` symbol outline (Aerial); moved off `<leader>ao` so `<leader>a` stays AI-only.
- Mermaid diagram support: `kevalin/mermaid.nvim` + `custom.mermaid_markdown` for ```mermaid fences in markdown; Snacks `image` inline charts when `mmdc`/`magick` available; `render-markdown` skips mermaid code blocks.
- `moyiz/blink-emoji.nvim` emoji completion in insert mode (`:smile` → 😄) via blink.cmp.
- `custom.tasks` + `custom.tasks_ui` Overseer-style workspace task panel: task list + live output pane, hidden PTY buffers, `<leader>tm` toggle, list keymaps (`r` run, `s` stop, `x` kill, `R` restart, `i` interact), `.nvim/tasks.lua` persistence; `:TaskUI`, `:TaskRun`, `:TaskShow`, `:TaskStop`, `:TaskKill`, `:TaskHide`, `:TaskAdd`.
- `felixcuello/neovim-cursor` terminal integration for Cursor Agent (`cursor agent`) with `<leader>aa` toggle, `<leader>an` new session, `<leader>at` select, and `<leader>ar` rename.
- `custom.cursor_chat` helpers and Avante-parity hotkeys to attach context to the agent terminal: `<leader>as` (selection), `<leader>ac` (current file), `<leader>aB` (all named buffers), `<leader>af` (focus agent); visual `<leader>aa` now shows the agent without toggling it closed.
- `custom.windows` window and buffer controls under `<leader>w` (splits, close, equalize, resize, buffer next/prev/close) plus `<S-Arrow>` split resizing; `:Cvsplit` / `:Chsplit` user commands restored.
- DataGrip-style SQL workflow via `vim-dadbod`, `vim-dadbod-ui`, and `vim-dadbod-completion` with `<leader>D` keymaps, schema-aware blink completion, `sqlls` LSP, Treesitter `sql` parser, and `sqlfluff` formatting/linting.
- Lazygit `G` custom command for AI-generated commit messages via `scripts/lazygit-ai-commit.ps1` (Cursor `agent -p`; scope menu for staged vs all changes; `output: terminal` for commit editor).
- Diffview keymaps under `<leader>g`: `gd` open changes, `gD` toggle, `gH` file history, `gP` vs last commit.
- `custom.msgarea` helper for closing, resetting, and routing lightweight status output through msgarea.
- `mini.pick` as the primary picker surface, routed into msgarea when available.
- Restored `which-key.nvim` with auto-discovery from `desc` keymaps plus `<leader>?` / `<leader><leader>` cheat sheets.
- Enabled `99.nvim` with a custom `CursorCliProvider` using the shared Cursor Agent CLI (`cursor_agent.print_command`) on Windows via `node.exe index.js --print`.
- Replaced `agentic.nvim` with `avante.nvim` using `cursor-acp` and shared `cursor_agent.acp_provider()` Windows spawn helpers.
- Added `blink.cmp` (pinned to `1.*`) with `blink.compat` for Avante completion sources.
- Added `custom.wtf_cursor` adapter to run wtf diagnose/fix through Cursor CLI `--print` on Windows-safe spawn paths.

### Fixed
- Task panel crash on open: nui tree nodes expose fields on the node directly (`node.id`), not `node.data`.

### Changed
- Lazygit AI commit (`G`): spawn Cursor Agent `node.exe` directly with `--print --model composer-2.5-fast`, diff truncation, and `CURSOR_COMMIT_MODEL` override (avoids agent.cmd double-PowerShell hop).
- Task stop (`<leader>ts`, `s` in panel) focuses output and sends Ctrl+C for interactive y/n prompts.
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
- Fixed Trouble workspace diagnostics by requesting `vim.lsp.buf.workspace_diagnostics()`, using basedpyright `disablePullDiagnostics` + `diagnosticMode = 'workspace'` so unopened project files are analyzed, and debouncing Trouble open until diagnostics arrive.
- Fixed basedpyright unresolved imports by removing the global `python.pythonPath` override and auto-selecting `.venv` / `venv` in the project root on LSP attach.
- Fixed `wilder.nvim` popup render crash (`E704` / `E714` in `popupmenu_devicons`) by removing the devicons renderer column from `lua/plugins/wilder.lua`.
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
