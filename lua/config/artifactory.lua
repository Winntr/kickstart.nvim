--- ACA Artifactory defaults for Mason (npm / PyPI). No secrets in repo.
local M = {}

local HOST = 'acadartifactory.jfrog.io'

local function npm_registry()
  local from_env = os.getenv 'ARTIFACTORY_NPM_REGISTRY'
  if from_env and from_env ~= '' then
    return from_env
  end
  return ('https://%s/artifactory/api/npm/npm/'):format(HOST)
end

---@return MasonSettings
function M.mason()
  local pip_install_args = vim.g.mason_pip_install_args
  if type(pip_install_args) ~= 'table' then
    -- ponytail: do not pass a credential-less --index-url; it overrides %APPDATA%\pip\pip.ini
    local index_url = os.getenv 'ARTIFACTORY_PYPI_INDEX_URL'
    if index_url and index_url ~= '' then
      pip_install_args = {
        '--index-url',
        index_url,
        '--trusted-host',
        HOST,
      }
    else
      pip_install_args = {
        '--trusted-host',
        HOST,
      }
    end
  end

  local npm_install_args = vim.g.mason_npm_install_args
  if type(npm_install_args) ~= 'table' then
    npm_install_args = {
      '--registry',
      npm_registry(),
    }
  end

  return {
    -- ponytail: client provider first avoids api.mason-registry.dev on some VPNs
    providers = {
      'mason.providers.client',
      'mason.providers.registry-api',
    },
    pip = {
      upgrade_pip = false,
      install_args = pip_install_args,
    },
    npm = {
      install_args = npm_install_args,
    },
    log_level = vim.log.levels.INFO,
  }
end

return M
