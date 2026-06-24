# SQL Workflow in Neovim

This configuration provides a DataGrip-like SQL workflow using Dadbod, DBUI, blink completion, SQL LSP, Treesitter, and sqlfluff.

## Stack

| Component | Plugin / Tool | Purpose |
|-----------|---------------|---------|
| Query execution | `vim-dadbod` | Run SQL against configured connections (`:DB`) |
| Schema browser | `vim-dadbod-ui` | Browse tables, saved queries, result buffers |
| Autocomplete | `vim-dadbod-completion` + `blink.cmp` | Table/column completion from live DB metadata |
| Language server | `sqlls` (Mason) / `sql-language-server` (binary) | SQL diagnostics and LSP completion |
| Syntax | Treesitter `sql` | Highlighting and indentation |
| Format / lint | `sqlfluff` via conform + nvim-lint | SQL formatting and linting |

## Keymaps

| Keymap | Action |
|--------|--------|
| `<leader>Dt` | Toggle DBUI |
| `<leader>Df` | Find DB buffer |
| `<leader>Dr` | Rename DB buffer |
| `<leader>Dq` | Last query info |
| `<leader>Da` | Add connection |
| `<leader>cf` | Format buffer (existing; works in SQL buffers) |

Press `<leader>D` to see the Database group in which-key.

## Database Connections

Connections are **not** stored in Git. Configure them in a local file:

**File:** `lua/config/local.lua` (gitignored)

```lua
-- lua/config/local.lua
vim.g.dbs = {
  -- Named connections for DBUI / Dadbod
  dev_pg = os.getenv('DATABASE_URL') or 'postgresql://user:pass@localhost:5432/mydb',
  analytics = os.getenv('ANALYTICS_DB_URL'),
}
```

### Environment variables (recommended)

Set connection URLs in your shell profile instead of hardcoding credentials:

```powershell
# PowerShell profile example
$env:DATABASE_URL = "postgresql://user:pass@localhost:5432/mydb"
$env:ANALYTICS_DB_URL = "postgresql://user:pass@analytics-host:5432/warehouse"
```

Then reference them in `lua/config/local.lua`:

```lua
vim.g.dbs = {
  dev = os.getenv('DATABASE_URL'),
  analytics = os.getenv('ANALYTICS_DB_URL'),
}
```

### Connection URL formats

Dadbod supports standard URLs:

- PostgreSQL: `postgresql://user:pass@host:5432/dbname`
- MySQL: `mysql://user:pass@host:3306/dbname`
- SQLite: `sqlite:path/to/file.db`
- SQL Server: `sqlserver://user:pass@host:1433/dbname`

## Usage

1. Create `lua/config/local.lua` with your `vim.g.dbs` entries.
2. Restart Neovim or run `:Lazy sync` if plugins are new.
3. Run `:MasonToolsInstall` to install `sqlls` and `sqlfluff`.
4. Press `<leader>Dt` to open DBUI.
5. Open or create a `.sql` buffer, select a connection in DBUI, and write queries.
6. Execute with Dadbod/DBUI commands from the UI or `:DB <query>`.

## Autocomplete

In SQL buffers, completion includes:

- **Dadbod** — tables, columns, and schema objects from the active DB connection
- **LSP** — `sqlls` keyword and syntax-aware suggestions
- **Snippets / buffer** — standard blink sources

Schema-aware Dadbod completion requires an active connection configured in `vim.g.dbs` and selected in DBUI for the buffer.

## Formatting and Linting

SQL buffers use `sqlfluff` for format-on-save and lint-on-read/write.

Default dialect is ANSI unless a project `.sqlfluff` config overrides it. Add a `.sqlfluff` file at your project root for dialect-specific rules:

```ini
[sqlfluff]
dialect = postgres
```

## Filetypes

Recognized SQL-related filetypes:

- `sql` — `.sql`
- `pgsql` — `.pgsql`
- `mysql` — `.mysql`
- `plsql` — `.plsql`

## Troubleshooting

### Mason install fails for sqlfluff

On Windows, ensure Python venv support is available. This config uses a Neovim data-dir venv for the Python host (`init.lua`). If Mason reports pip/venv errors, run `:MasonLog` and install `python3-venv` or fix the Python environment.

### No table/column completion

1. Confirm `vim.g.dbs` is set in `lua/config/local.lua`.
2. Open DBUI (`<leader>Dt`) and attach the buffer to a connection.
3. Ensure `vim-dadbod-completion` loaded (`:Lazy` → check plugin status).

### sqlls not attaching

Run `:Mason` and confirm `sqlls` is installed. Check `:LspInfo` in a SQL buffer.
