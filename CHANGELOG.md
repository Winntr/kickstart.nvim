## [Unreleased]

### Changed
- Updated `agentic.nvim` Windows `cursor-acp` startup to use `custom.cursor_agent.agentic_acp_provider()`, spawning Cursor Agent `node.exe` directly with the `acp` subcommand instead of PowerShell or `.cmd` wrappers.

### Fixed
- Fixed Agentic Cursor ACP initialization failures on Windows (`disconnected` / `-32000`) caused by wrapper processes exiting before stdio ACP transport attached.
- Fixed Windows Terminal tab spam when opening Agentic by patching ACP spawns to use hidden, non-detached console creation on Windows.
- Fixed a Windows launch regression where Agentic used Cursor's internal `node.exe` entrypoint without the required `acp` subcommand, which could start the interactive CLI and spawn extra terminal tabs.
