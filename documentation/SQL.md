# SQL Editing in Neovim

SQL buffers use LSP, Treesitter, and sqlfluff only. Query execution is not integrated in Neovim; use DataGrip or another client to run SQL against databases.

## Stack

| Component | Tool | Purpose |
|-----------|------|---------|
| Language server | `sqlls` (Mason) | Diagnostics and LSP completion |
| Syntax | Treesitter `sql` | Highlighting and indentation |
| Format / lint | `sqlfluff` via conform + nvim-lint | Format-on-save and lint |

## Usage

1. Open a `.sql` buffer (or `.mysql`, `.pgsql`, `.plsql`).
2. Run `:Mason` and install `sqlls` and `sqlfluff` if needed.
3. Use `<leader>cf` to format.

## Formatting

Add a project `.sqlfluff` for dialect-specific rules:

```ini
[sqlfluff]
dialect = postgres
```

## Troubleshooting

### Mason install fails for sqlfluff

On Windows, ensure Python venv support is available. Check `:MasonLog` if install fails.

### sqlls not attaching

Run `:Mason` and confirm `sqlls` is installed. Check `:LspInfo` in a SQL buffer.
