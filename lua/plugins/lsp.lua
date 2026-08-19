return {
  {
    'neovim/nvim-lspconfig',
    lazy = false,
    enabled = function()
      return not vim.g.vscode
    end,
    dependencies = {
      { 'williamboman/mason.nvim', opts = {} },
      'WhoIsSethDaniel/mason-tool-installer.nvim',
      { 'j-hui/fidget.nvim', opts = {} },
    },
    config = function()
      local function project_python(root)
        if not root then
          return nil
        end
        local rel = vim.fn.has 'win32' == 1 and 'Scripts/python.exe' or 'bin/python'
        for _, venv in ipairs { '.venv', 'venv' } do
          local py = root .. '/' .. venv .. '/' .. rel
          if vim.uv.fs_stat(py) then
            return vim.fn.fnamemodify(py, ':p')
          end
        end
        return nil
      end

      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('nvim-lsp-attach', { clear = true }),
        callback = function(event)
          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if client and client.name == 'basedpyright' then
            local py = project_python(client.root_dir)
            local settings = vim.tbl_deep_extend('force', client.settings or {}, {
              basedpyright = {
                analysis = { diagnosticMode = 'workspace' },
              },
              python = py and { pythonPath = py } or {},
            })
            client.settings = settings
            client:notify('workspace/didChangeConfiguration', { settings = settings })
            vim.defer_fn(function()
              if client:supports_method('workspace/diagnostic') then
                vim.lsp.buf.workspace_diagnostics { client_id = client.id }
              end
            end, 500)
          end

          local map = function(keys, func, desc, mode)
            vim.keymap.set(mode or 'n', keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
          end

          map('gd', vim.lsp.buf.definition, 'Goto definition')
          map('gr', vim.lsp.buf.references, 'References')
          map('gI', vim.lsp.buf.implementation, 'Goto implementation')
          map('gD', vim.lsp.buf.declaration, 'Goto declaration')
          map('K', vim.lsp.buf.hover, 'Hover docs')
          map('<leader>rn', vim.lsp.buf.rename, 'Rename')
          map('<leader>ca', vim.lsp.buf.code_action, 'Code action', { 'n', 'x' })
          map(']d', function()
            vim.diagnostic.jump { count = 1 }
          end, 'Next diagnostic')
          map('[d', function()
            vim.diagnostic.jump { count = -1 }
          end, 'Previous diagnostic')
        end,
      })

      local capabilities = vim.lsp.protocol.make_client_capabilities()
      local ok_blink, blink = pcall(require, 'blink.cmp')
      if ok_blink then
        capabilities = blink.get_lsp_capabilities(capabilities)
      end

      vim.lsp.config('*', { capabilities = capabilities })

      local function angular_root(fname)
        return vim.fs.root(fname, { 'angular.json', 'nx.json' })
      end

      vim.lsp.config('basedpyright', {
        -- ponytail: pull diagnostics break workspace/diagnostic on basedpyright; push + workspace mode publishes unopened files
        init_options = { disablePullDiagnostics = true },
        settings = {
          basedpyright = {
            analysis = {
              typeCheckingMode = 'standard',
              autoSearchPaths = true,
              diagnosticMode = 'workspace',
            },
          },
        },
      })

      vim.lsp.config('html', {
        cmd = { 'vscode-html-language-server', '--stdio' },
        filetypes = { 'html', 'templ', 'htmlangular' },
        init_options = {
          configurationSection = { 'html', 'css', 'javascript' },
          embeddedLanguages = { css = true, javascript = true },
          provideFormatter = false,
        },
      })

      vim.lsp.config('cssls', {
        cmd = { 'vscode-css-language-server', '--stdio' },
        filetypes = { 'css', 'scss', 'less' },
        settings = {
          css = { validate = true, lint = { unknownAtRules = 'ignore' } },
          scss = { validate = true, lint = { unknownAtRules = 'ignore' } },
        },
      })

      vim.lsp.config('tailwindcss', {
        cmd = { 'tailwindcss-language-server', '--stdio' },
        filetypes = {
          'html',
          'css',
          'scss',
          'javascript',
          'typescript',
          'typescriptreact',
          'javascriptreact',
          'vue',
          'svelte',
          'htmlangular',
        },
        settings = {
          tailwindCSS = {
            classAttributes = { 'class', 'className', 'classList', 'ngClass' },
            validate = true,
          },
        },
        root_markers = {
          'tailwind.config.js',
          'tailwind.config.ts',
          'postcss.config.js',
          'postcss.config.ts',
          'package.json',
          '.git',
        },
      })

      vim.lsp.config('lua_ls', {
        settings = {
          Lua = { completion = { callSnippet = 'Replace' } },
        },
      })

      vim.lsp.config('ts_ls', {
        root_dir = function(bufnr, on_dir)
          local fname = vim.api.nvim_buf_get_name(bufnr)
          if fname == '' or angular_root(fname) then
            on_dir(nil)
            return
          end
          on_dir(vim.fs.root(fname, { 'package.json', 'tsconfig.json', '.git' }))
        end,
        init_options = {
          plugins = {
            {
              name = '@vue/typescript-plugin',
              location = vim.fn.stdpath 'data'
                .. '/mason/packages/vue-language-server/node_modules/@vue/language-server',
              languages = { 'vue' },
              configNamespace = 'typescript',
            },
          },
        },
        filetypes = { 'typescript', 'javascript', 'javascriptreact', 'typescriptreact', 'vue' },
      })

      vim.lsp.config('vue_ls', {
        root_dir = function(bufnr, on_dir)
          local fname = vim.api.nvim_buf_get_name(bufnr)
          if fname == '' or angular_root(fname) then
            on_dir(nil)
            return
          end
          on_dir(
            vim.fs.root(fname, {
              'nuxt.config.ts',
              'nuxt.config.js',
              'vue.config.js',
              'vite.config.ts',
              'vite.config.js',
              'package.json',
            })
          )
        end,
      })

      local sqlls_connections = {}
      pcall(function()
        pcall(require, 'config.local')
        sqlls_connections = require('custom.db_url').sqlls_connections()
      end)

      vim.lsp.config('sqlls', {
        filetypes = { 'sql', 'mysql', 'plsql', 'pgsql', 'redshift' },
        settings = {
          sqlLanguageServer = {
            connections = sqlls_connections,
          },
        },
      })

      vim.lsp.config('gopls', {
        filetypes = { 'go', 'gomod', 'gowork', 'gotmpl' },
        root_markers = { 'go.work', 'go.mod', '.git' },
        settings = {
          gopls = {
            gofumpt = true,
            staticcheck = true,
            analyses = {
              unusedparams = true,
            },
            completionDocumentation = true,
            usePlaceholders = true,
            hints = {
              assignVariableTypes = true,
              compositeLiteralFields = true,
              compositeLiteralTypes = true,
              parameterNames = true,
            },
          },
        },
      })

      vim.lsp.config('angularls', {
        cmd = {
          'ngserver',
          '--stdio',
          '--tsProbeLocations',
          vim.fn.stdpath 'data',
          vim.fn.getcwd() .. '/node_modules',
          '--ngProbeLocations',
          vim.fn.stdpath 'data' .. '/@angular/language-server/node_modules',
          vim.fn.getcwd() .. '/node_modules/@angular/language-server/node_modules',
          '--angularCoreVersion',
        },
        filetypes = { 'typescript', 'html', 'typescriptreact', 'htmlangular' },
        root_markers = { 'angular.json', 'nx.json' },
      })

      local servers = {
        'basedpyright',
        'html',
        'cssls',
        'tailwindcss',
        'lua_ls',
        'ts_ls',
        'vue_ls',
        'angularls',
        'sqlls',
        'gopls',
      }

      for _, server in ipairs(servers) do
        vim.lsp.enable(server)
      end

      require('mason-tool-installer').setup {
        ensure_installed = {
          'stylua',
          'html-lsp',
          'css-lsp',
          'tailwindcss-language-server',
          'typescript-language-server',
          'angular-language-server',
          'vue-language-server',
          'lua-language-server',
          'sqlls',
          'sqlfluff',
          'gopls',
        },
      }

      -- Neovim 0.12+: native :lsp restart / :checkhealth vim.lsp (old :LspInfo/:LspRestart removed)
      vim.api.nvim_create_user_command('LspInfo', function()
        vim.cmd.checkhealth('vim.lsp')
      end, { desc = 'Show attached LSP clients (checkhealth vim.lsp)' })

      vim.api.nvim_create_user_command('LspRestart', function(opts)
        local args = vim.trim(opts.args)
        if args == '' then
          vim.cmd.lsp('restart')
        else
          vim.cmd.lsp({ 'restart', args })
        end
      end, { nargs = '?', desc = 'Restart LSP (optional server name, e.g. gopls)' })

      vim.api.nvim_create_user_command('LspLog', function()
        vim.cmd.edit(vim.fn.stdpath 'state' .. '/lsp.log')
      end, { desc = 'Open LSP log file' })
    end,
  },
}
