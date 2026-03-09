#!/usr/bin/env python3
"""
ODBC Database Adapter for vim-dadbod
Executes SQL queries via ODBC DSN connections using pyodbc.

Features:
- File-based JSON caching with configurable TTL (default 8 hours)
- Lazy schema loading
- System schema exclusion
- Table limits
- Connection testing

Usage:
  uv run --with pyodbc db-odbc.py --dsn DSN_NAME [options] MODE

Modes:
  --query "SQL"        Execute a single SQL query
  --query-stdin        Read SQL from stdin
  --query-file FILE    Read SQL from file
  --interactive        Interactive REPL mode
  --tables             List tables (with caching)
  --columns TABLE      List columns for table (with caching)
  --schemas            List schemas (with caching)
  --check-connection   Test database connection

Options:
  --database DB        Database name (optional)
  --schema SCHEMA      Filter to specific schema
  --exclude-system     Exclude system schemas (pg_catalog, information_schema, pg_internal)
  --table-limit N      Max tables to return (default: 1000)
  --cache-ttl SECONDS  Cache TTL in seconds (default: 28800 = 8 hours)
  --no-cache           Bypass cache (always fetch fresh)
  --clear-cache        Clear all cached data for this DSN
  --cache-status       Show cache status (what's cached, age)
"""

import argparse
import hashlib
import json
import os
import platform
import sys
import time
from pathlib import Path

import pyodbc


# Default configuration
DEFAULT_CACHE_TTL = 28800  # 8 hours in seconds
DEFAULT_TABLE_LIMIT = 1000
SYSTEM_SCHEMAS = {'pg_catalog', 'information_schema', 'pg_internal'}


def get_cache_dir() -> Path:
    """Get platform-appropriate cache directory."""
    if platform.system() == 'Windows':
        base = os.environ.get('TEMP', os.environ.get('TMP', 'C:\\Temp'))
    else:
        base = '/tmp'
    cache_dir = Path(base) / 'nvim-db-cache'
    cache_dir.mkdir(parents=True, exist_ok=True)
    return cache_dir


def get_dsn_hash(dsn: str, database: str | None = None) -> str:
    """Create a hash identifier for DSN+database combination."""
    key = f"{dsn}:{database or ''}"
    return hashlib.md5(key.encode()).hexdigest()[:12]


def get_cache_file(dsn: str, database: str | None, cache_type: str, extra: str = "") -> Path:
    """Get cache file path for specific data type."""
    dsn_hash = get_dsn_hash(dsn, database)
    if extra:
        filename = f"{dsn_hash}_{cache_type}_{extra}.json"
    else:
        filename = f"{dsn_hash}_{cache_type}.json"
    return get_cache_dir() / filename


def read_cache(cache_file: Path, ttl: int) -> list | None:
    """Read from cache if valid, return None if stale or missing."""
    if not cache_file.exists():
        return None
    try:
        data = json.loads(cache_file.read_text())
        if time.time() - data.get('timestamp', 0) < ttl:
            return data.get('items', [])
        return None  # Stale
    except (json.JSONDecodeError, KeyError):
        return None


def write_cache(cache_file: Path, items: list) -> None:
    """Write items to cache with current timestamp."""
    data = {
        'timestamp': time.time(),
        'items': items
    }
    cache_file.write_text(json.dumps(data, indent=2))


def clear_cache_for_dsn(dsn: str, database: str | None) -> int:
    """Clear all cache files for a DSN. Returns count of files cleared."""
    dsn_hash = get_dsn_hash(dsn, database)
    cache_dir = get_cache_dir()
    count = 0
    for f in cache_dir.glob(f"{dsn_hash}_*.json"):
        f.unlink()
        count += 1
    return count


def get_cache_status(dsn: str, database: str | None) -> dict:
    """Get status of all cache files for a DSN."""
    dsn_hash = get_dsn_hash(dsn, database)
    cache_dir = get_cache_dir()
    status = {'dsn': dsn, 'database': database, 'files': []}
    
    for f in cache_dir.glob(f"{dsn_hash}_*.json"):
        try:
            data = json.loads(f.read_text())
            age_seconds = time.time() - data.get('timestamp', 0)
            age_hours = age_seconds / 3600
            status['files'].append({
                'name': f.name,
                'items': len(data.get('items', [])),
                'age_hours': round(age_hours, 2),
                'age_seconds': int(age_seconds)
            })
        except:
            status['files'].append({'name': f.name, 'error': 'corrupt'})
    
    return status


def get_connection(dsn: str, database: str | None = None) -> pyodbc.Connection:
    """Create ODBC connection using DSN."""
    conn_str = f"DSN={dsn}"
    if database:
        conn_str += f";Database={database}"
    return pyodbc.connect(conn_str)


def check_connection(dsn: str, database: str | None) -> dict:
    """Test database connection and return status."""
    try:
        conn = get_connection(dsn, database)
        cursor = conn.cursor()
        # Simple query to verify connection works
        cursor.execute("SELECT 1")
        cursor.fetchone()
        cursor.close()
        conn.close()
        return {'success': True, 'message': f'Connected to {dsn}' + (f'/{database}' if database else '')}
    except pyodbc.Error as e:
        return {'success': False, 'message': str(e)}


def format_table(headers: list[str], rows: list[tuple]) -> str:
    """Format results as ASCII table compatible with dadbod."""
    if not headers:
        return ""

    # Calculate column widths
    col_widths = [len(str(h)) for h in headers]
    for row in rows:
        for i, val in enumerate(row):
            col_widths[i] = max(col_widths[i], len(str(val) if val is not None else "NULL"))

    # Build table
    lines = []

    # Header
    header_line = " | ".join(str(h).ljust(col_widths[i]) for i, h in enumerate(headers))
    lines.append(header_line)

    # Separator
    sep_line = "-+-".join("-" * w for w in col_widths)
    lines.append(sep_line)

    # Rows
    for row in rows:
        row_line = " | ".join(
            (str(val) if val is not None else "NULL").ljust(col_widths[i])
            for i, val in enumerate(row)
        )
        lines.append(row_line)

    # Row count
    lines.append(f"({len(rows)} row{'s' if len(rows) != 1 else ''})")

    return "\n".join(lines)


def execute_query(dsn: str, database: str | None, query: str) -> None:
    """Execute a single query and print results."""
    try:
        conn = get_connection(dsn, database)
        cursor = conn.cursor()
        cursor.execute(query)

        # Check if query returns results
        if cursor.description:
            headers = [col[0] for col in cursor.description]
            rows = cursor.fetchall()
            print(format_table(headers, rows))
        else:
            # DML statement
            print(f"Query OK, {cursor.rowcount} row(s) affected")

        conn.commit()
        cursor.close()
        conn.close()
    except pyodbc.Error as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


def list_schemas(
    dsn: str,
    database: str | None,
    exclude_system: bool = True,
    cache_ttl: int = DEFAULT_CACHE_TTL,
    no_cache: bool = False
) -> list[str]:
    """List all schemas in the database."""
    cache_file = get_cache_file(dsn, database, 'schemas')
    
    # Try cache first
    if not no_cache:
        cached = read_cache(cache_file, cache_ttl)
        if cached is not None:
            if exclude_system:
                return [s for s in cached if s not in SYSTEM_SCHEMAS]
            return cached
    
    # Fetch from database
    try:
        conn = get_connection(dsn, database)
        cursor = conn.cursor()
        
        # Use ODBC metadata to get schemas
        schemas = []
        for row in cursor.tables():
            schema = row.table_schem
            if schema and schema not in schemas:
                schemas.append(schema)
        
        schemas = sorted(set(schemas))
        cursor.close()
        conn.close()
        
        # Cache ALL schemas (we filter system schemas on output)
        write_cache(cache_file, schemas)
        
        if exclude_system:
            return [s for s in schemas if s not in SYSTEM_SCHEMAS]
        return schemas
    except pyodbc.Error as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


def list_tables(
    dsn: str,
    database: str | None,
    schema: str | None = None,
    exclude_system: bool = True,
    table_limit: int = DEFAULT_TABLE_LIMIT,
    cache_ttl: int = DEFAULT_CACHE_TTL,
    no_cache: bool = False
) -> list[str]:
    """List tables in the database, optionally filtered by schema."""
    cache_key = schema or 'all'
    cache_file = get_cache_file(dsn, database, 'tables', cache_key)
    
    # Try cache first
    if not no_cache:
        cached = read_cache(cache_file, cache_ttl)
        if cached is not None:
            result = cached
            if exclude_system and not schema:
                result = [t for t in result if not any(t.startswith(f"{s}.") for s in SYSTEM_SCHEMAS)]
            return result[:table_limit]
    
    # Fetch from database
    try:
        conn = get_connection(dsn, database)
        cursor = conn.cursor()

        tables = []
        
        # Get tables
        for row in cursor.tables(tableType="TABLE", schema=schema):
            schema_name = row.table_schem or ""
            name = row.table_name
            if schema_name:
                tables.append(f"{schema_name}.{name}")
            else:
                tables.append(name)

        # Also get views
        for row in cursor.tables(tableType="VIEW", schema=schema):
            schema_name = row.table_schem or ""
            name = row.table_name
            if schema_name:
                tables.append(f"{schema_name}.{name}")
            else:
                tables.append(name)

        tables = sorted(set(tables))
        cursor.close()
        conn.close()
        
        # Cache ALL tables for this schema (filter on output)
        write_cache(cache_file, tables)
        
        if exclude_system and not schema:
            tables = [t for t in tables if not any(t.startswith(f"{s}.") for s in SYSTEM_SCHEMAS)]
        
        return tables[:table_limit]
    except pyodbc.Error as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


def list_columns(
    dsn: str,
    database: str | None,
    table: str,
    cache_ttl: int = DEFAULT_CACHE_TTL,
    no_cache: bool = False
) -> list[str]:
    """List all columns for a table."""
    # Normalize table name for cache key (replace dots)
    cache_key = table.replace('.', '_')
    cache_file = get_cache_file(dsn, database, 'columns', cache_key)
    
    # Try cache first
    if not no_cache:
        cached = read_cache(cache_file, cache_ttl)
        if cached is not None:
            return cached
    
    # Fetch from database
    try:
        conn = get_connection(dsn, database)
        cursor = conn.cursor()

        # Parse schema.table format
        schema = None
        table_name = table
        if "." in table:
            parts = table.split(".", 1)
            schema = parts[0]
            table_name = parts[1]

        columns = []
        for row in cursor.columns(table=table_name, schema=schema):
            columns.append(row.column_name)

        cursor.close()
        conn.close()
        
        # Cache the columns
        write_cache(cache_file, columns)
        
        return columns
    except pyodbc.Error as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


def interactive_mode(dsn: str, database: str | None) -> None:
    """Run interactive REPL for SQL queries."""
    try:
        conn = get_connection(dsn, database)
        cursor = conn.cursor()

        db_display = f"{dsn}" + (f"/{database}" if database else "")
        print(f"Connected to {db_display}")
        print("Type SQL queries, end with semicolon. Type 'exit' or Ctrl+D to quit.")
        print()

        buffer = []
        while True:
            try:
                prompt = f"{db_display}> " if not buffer else "... "
                line = input(prompt)

                # Handle exit commands
                if line.strip().lower() in ("exit", "quit", "\\q"):
                    break

                buffer.append(line)
                full_query = "\n".join(buffer)

                # Execute when we see a semicolon
                if ";" in line:
                    # Split on semicolon and execute each statement
                    statements = full_query.split(";")
                    for stmt in statements:
                        stmt = stmt.strip()
                        if stmt:
                            try:
                                cursor.execute(stmt)
                                if cursor.description:
                                    headers = [col[0] for col in cursor.description]
                                    rows = cursor.fetchall()
                                    print(format_table(headers, rows))
                                else:
                                    print(f"Query OK, {cursor.rowcount} row(s) affected")
                                conn.commit()
                            except pyodbc.Error as e:
                                print(f"Error: {e}")
                    buffer = []
                    print()

            except EOFError:
                break

        cursor.close()
        conn.close()
        print("\nGoodbye!")

    except pyodbc.Error as e:
        print(f"Connection error: {e}", file=sys.stderr)
        sys.exit(1)


def main():
    parser = argparse.ArgumentParser(
        description="ODBC Database Adapter for vim-dadbod",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__
    )
    
    # Connection options
    parser.add_argument("--dsn", required=True, help="ODBC Data Source Name")
    parser.add_argument("--database", "-d", help="Database name (optional)")
    
    # Mode options (mutually exclusive)
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--query", "-q", help="SQL query to execute")
    mode.add_argument("--query-stdin", action="store_true", help="Read SQL from stdin")
    mode.add_argument("--query-file", help="Read SQL from file")
    mode.add_argument("--interactive", "-i", action="store_true", help="Interactive REPL mode")
    mode.add_argument("--tables", "-t", action="store_true", help="List tables")
    mode.add_argument("--columns", "-c", help="List columns for table")
    mode.add_argument("--schemas", action="store_true", help="List schemas")
    mode.add_argument("--check-connection", action="store_true", help="Test database connection")
    mode.add_argument("--clear-cache", action="store_true", help="Clear cache for this DSN")
    mode.add_argument("--cache-status", action="store_true", help="Show cache status")
    
    # Filter options
    parser.add_argument("--schema", "-s", help="Filter to specific schema")
    parser.add_argument("--exclude-system", action="store_true", default=True,
                        help="Exclude system schemas (default: true)")
    parser.add_argument("--include-system", action="store_true",
                        help="Include system schemas")
    parser.add_argument("--table-limit", type=int, default=DEFAULT_TABLE_LIMIT,
                        help=f"Max tables to return (default: {DEFAULT_TABLE_LIMIT})")
    
    # Cache options
    parser.add_argument("--cache-ttl", type=int, default=DEFAULT_CACHE_TTL,
                        help=f"Cache TTL in seconds (default: {DEFAULT_CACHE_TTL})")
    parser.add_argument("--no-cache", action="store_true",
                        help="Bypass cache, always fetch fresh")
    
    # Output options
    parser.add_argument("--json", action="store_true", help="Output as JSON")

    args = parser.parse_args()
    
    # Handle --include-system overriding default --exclude-system
    exclude_system = not args.include_system

    if args.check_connection:
        result = check_connection(args.dsn, args.database)
        if args.json:
            print(json.dumps(result))
        else:
            status = "✓" if result['success'] else "✗"
            print(f"{status} {result['message']}")
        sys.exit(0 if result['success'] else 1)
        
    elif args.clear_cache:
        count = clear_cache_for_dsn(args.dsn, args.database)
        if args.json:
            print(json.dumps({'cleared': count}))
        else:
            print(f"Cleared {count} cache file(s)")
        
    elif args.cache_status:
        status = get_cache_status(args.dsn, args.database)
        if args.json:
            print(json.dumps(status, indent=2))
        else:
            print(f"Cache status for {status['dsn']}" + (f"/{status['database']}" if status['database'] else ""))
            if not status['files']:
                print("  No cached data")
            for f in status['files']:
                if 'error' in f:
                    print(f"  {f['name']}: {f['error']}")
                else:
                    print(f"  {f['name']}: {f['items']} items, {f['age_hours']}h old")
        
    elif args.interactive:
        interactive_mode(args.dsn, args.database)
        
    elif args.schemas:
        schemas = list_schemas(
            args.dsn, args.database,
            exclude_system=exclude_system,
            cache_ttl=args.cache_ttl,
            no_cache=args.no_cache
        )
        if args.json:
            print(json.dumps(schemas))
        else:
            for schema in schemas:
                print(schema)
        
    elif args.tables:
        tables = list_tables(
            args.dsn, args.database,
            schema=args.schema,
            exclude_system=exclude_system,
            table_limit=args.table_limit,
            cache_ttl=args.cache_ttl,
            no_cache=args.no_cache
        )
        if args.json:
            print(json.dumps(tables))
        else:
            for table in tables:
                print(table)
                
    elif args.columns:
        columns = list_columns(
            args.dsn, args.database, args.columns,
            cache_ttl=args.cache_ttl,
            no_cache=args.no_cache
        )
        if args.json:
            print(json.dumps(columns))
        else:
            for col in columns:
                print(col)
                
    elif args.query:
        execute_query(args.dsn, args.database, args.query)
        
    elif args.query_stdin:
        query = sys.stdin.read().strip()
        if query:
            execute_query(args.dsn, args.database, query)
            
    elif args.query_file:
        with open(args.query_file, 'r') as f:
            query = f.read().strip()
        if query:
            execute_query(args.dsn, args.database, query)
            
    else:
        parser.print_help()
        sys.exit(1)


if __name__ == "__main__":
    main()
