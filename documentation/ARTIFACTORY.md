# Artifactory (Mason, npm, pip)

Corporate npm and PyPI are proxied through `acadartifactory.jfrog.io`. Mason is configured in `lua/config/artifactory.lua` and loaded from the `mason.nvim` plugin spec in `lua/plugins/lsp.lua`.

## Mason

- **npm packages** (for example `typescript-language-server`): Mason runs `npm` from your PATH. User-level `%USERPROFILE%\.npmrc` supplies the Artifactory registry and token.
- **PyPI packages** (for example `basedpyright`, `sqlfluff`): Mason creates a per-package venv and runs `python -m pip install`. Pip reads **`%APPDATA%\pip\pip.ini`** for `index-url` and credentials.
- Mason only adds `--trusted-host` (and optional `ARTIFACTORY_PYPI_INDEX_URL`) so a bare `--index-url` does not override authenticated `pip.ini`.

Registry metadata: `providers` prefers `mason.providers.client` before `registry-api` for VPN-friendly resolution.

## PyPI credentials (`pip.ini`)

JFrog PyPI uses your **JFrog username** (for example `Trevor.Winn`), not the `email=` field from `.npmrc`.

Example `%APPDATA%\pip\pip.ini` (do not commit; contains secrets):

```ini
[global]
index-url = https://JFROG_USER:IDENTITY_OR_API_TOKEN@acadartifactory.jfrog.io/artifactory/api/pypi/pypi/simple
trusted-host = acadartifactory.jfrog.io
```

You can reuse the same identity token as npm when the username is correct. Test outside Neovim:

```powershell
python -m venv $env:TEMP\pip-test\venv
& $env:TEMP\pip-test\venv\Scripts\python.exe -m pip install basedpyright==1.40.1
```

## Overrides

Optional `lua/config/local.lua` (gitignored) or environment variables:

| Variable | Purpose |
|----------|---------|
| `ARTIFACTORY_PYPI_INDEX_URL` | Full PyPI simple index URL (include credentials if not using `pip.ini`) |
| `ARTIFACTORY_NPM_REGISTRY` | npm registry URL |
| `vim.g.mason_pip_install_args` | Replace Mason pip extra args entirely |
| `vim.g.mason_npm_install_args` | Replace Mason npm extra args entirely |

## GitHub release packages

Many Mason tools (for example `gopls`, `lua-language-server`) download GitHub release assets, not npm/PyPI. If those installs fail, ask platform engineering for a GitHub release mirror and set `github.download_url_template` in Mason settings (see `:help mason-download-mirror-github`).

## Troubleshooting

1. `:checkhealth mason` — PATH tools (`npm`, `python`, `curl`).
2. `:MasonLog` with `log_level = vim.log.levels.DEBUG` in `config.artifactory` if needed.
3. `:MasonUpdate` then `:MasonInstall basedpyright`.
4. Inside Neovim: `:lua print(vim.fn.exepath('npm'), vim.fn.exepath('python'))`.

See also `documentation/TROUBLESHOOTING.md` (Mason / basedpyright).
