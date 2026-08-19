# SQL Workflow (Neovim + DataGrip)

Edit in Neovim. **Run queries in DataGrip** — uses your existing JDBC drivers (Redshift, AWS Aurora MySQL, etc.) and saved data sources. No copying driver JARs, no `mysql`/`psql` CLI, no Harlequin adapters.

## Stack

| Layer | Tool | Purpose |
|-------|------|---------|
| Editing | Neovim + Treesitter | SQL buffers |
| LSP (optional) | `sqlls` via Mason | Diagnostics / completion in buffers |
| Format / lint | `sqlfluff` | Dialect-aware format and lint |
| Execution | **DataGrip** | Run SQL, schema browser, results — your configured drivers |

Harlequin and Dadbod are **not** used. They rely on separate Python or shell drivers, not DataGrip’s JDBC cache.

## Why not “hijack” DataGrip drivers?

DataGrip drivers are **JDBC JARs** for a JVM stack. Tools like Harlequin use **Python** drivers (`psycopg`, `pymysql`). Pointing them at `%APPDATA%\JetBrains\...\jdbc-drivers\` is fragile (Maven layout, missing JARs, version skew) and still does not give Neovim in-buffer execution.

The reliable approach: **open the file in DataGrip** and execute with your saved connections (`AWS_PROD_Redshift StgBiz`, Aurora MySQL, etc.).

## Keymaps

| Keymap | Action |
|--------|--------|
| `<leader>Dg` / `<leader>Dt` | Open current SQL file in DataGrip (`-e`, cursor line) |
| `<leader>Dp` | Open DataGrip project `~/DataGripProjects/Main` |
| `<leader>cf` | Format buffer (sqlfluff) |

Commands: `:DataGrip`, `:DataGripFile`, `:DataGripProject`

In DataGrip: pick the data source in the console toolbar, then run (Ctrl+Enter).

## Configuration

Copy `lua/config/local.lua.example` → `lua/config/local.lua` if you need overrides:

```lua
vim.g.datagrip_exe = 'C:\\Program Files\\JetBrains\\DataGrip 2023.3.4\\bin\\datagrip64.exe'
vim.g.datagrip_project = vim.fn.expand('$USER_HOME/DataGripProjects/Main')
```

Your shim (`Documents\Shims\Datagrip.bat`) also works if `datagrip` is on PATH.

## Filetypes

| Filetype | Files | sqlfluff dialect |
|----------|-------|------------------|
| `redshift` | `*.redshift.sql` | `redshift` |
| `pgsql` | `*.pgsql` | `postgres` |
| `mysql` | `*.mysql` | `mysql` |
| `sql` | `*.sql` | `ansi` or project `.sqlfluff` |

## Optional: sqlls in Neovim

Set env vars if you want LSP metadata in buffers (separate from DataGrip credentials store):

```powershell
$env:REDSHIFT_URL = "postgresql://..."
$env:AURORA_PG_URL = "postgresql://..."
$env:AURORA_MYSQL_URL = "mysql://..."
```

`:Mason` → install `sqlls` and `sqlfluff`.

## Workflow

1. Write SQL in Neovim (format, LSP, git).
2. `<leader>Dg` → file opens in DataGrip at your cursor line.
3. Select data source in DataGrip → execute.

## Troubleshooting

### DataGrip not found

Set `vim.g.datagrip_exe` to the full path to `datagrip64.exe`.

### File opens but no data source attached

DataGrip does not attach a datasource from the CLI automatically. Use the console’s data source dropdown (your saved Redshift / Aurora connections).

### LightEdit vs project

`-e` opens SQL in editor mode. `<leader>Dp` opens the **Main** project with full console history and data sources tree.
