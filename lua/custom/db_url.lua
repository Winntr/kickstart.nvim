--- Connection URL helpers for sqlls (optional). Query execution: use DataGrip.
local M = {}

local function env(name)
  local v = os.getenv(name)
  if v and v ~= '' then
    return v
  end
  return nil
end

function M.first_env(names)
  for _, name in ipairs(names) do
    local v = env(name)
    if v then
      return v
    end
  end
  return nil
end

function M.redshift_url()
  return M.first_env { 'REDSHIFT_URL', 'REDSHIFT_DATABASE_URL', 'AWS_REDSHIFT_URL' }
end

function M.aurora_postgres_url()
  return M.first_env {
    'AURORA_PG_URL',
    'AURORA_POSTGRES_URL',
    'AURORA_POSTGRESQL_URL',
    'DATABASE_URL',
  }
end

function M.aurora_mysql_url()
  return M.first_env { 'AURORA_MYSQL_URL', 'MYSQL_URL', 'AURORA_MYSQL_DATABASE_URL' }
end

function M.sqlls_connections()
  local connections = {}

  local rs = M.redshift_url()
  if rs then
    local conn = M._sqlls_from_url('redshift', rs, 'postgres')
    if conn then
      table.insert(connections, conn)
    end
  end

  local pg = M.aurora_postgres_url()
  if pg then
    local conn = M._sqlls_from_url('aurora_pg', pg, 'postgres')
    if conn then
      table.insert(connections, conn)
    end
  end

  local my = M.aurora_mysql_url()
  if my then
    local conn = M._sqlls_from_url('aurora_mysql', my, 'mysql')
    if conn then
      table.insert(connections, conn)
    end
  end

  return connections
end

function M._parse_url(url, adapter)
  local scheme, rest = url:match '^(%w+)://(.+)$'
  if not scheme or not rest then
    return nil
  end

  local userinfo, hostpart = rest:match '^([^@]+)@(.+)$'
  local user, password = '', ''
  if userinfo then
    user, password = userinfo:match '^([^:]*):?(.*)$'
  else
    hostpart = rest
  end

  local host, port, database = hostpart:match '^([^:/]+):?(%d*)/?(.*)$'
  if not host then
    return nil
  end

  if adapter == 'postgres' and scheme:match '^postgres' then
    port = port ~= '' and port or '5432'
  elseif adapter == 'mysql' and scheme == 'mysql' then
    port = port ~= '' and port or '3306'
  else
    return nil
  end

  database = (database or ''):gsub('%?.*$', '')

  return {
    host = host,
    port = tonumber(port),
    user = user,
    password = password,
    database = database,
  }
end

function M._sqlls_from_url(name, url, adapter)
  local parsed = M._parse_url(url, adapter)
  if not parsed then
    return nil
  end

  return {
    name = name,
    adapter = adapter,
    host = parsed.host,
    port = parsed.port,
    user = parsed.user,
    password = parsed.password,
    database = parsed.database,
  }
end

return M
