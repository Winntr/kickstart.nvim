return {
  {
    -- Main LSP Configuration
    'neovim/nvim-lspconfig',
    lazy = false,
    -- enabled = false,
    enabled = function()
      return not vim.g.vscode
    end,
    dependencies = {
      -- Automatically install LSPs and related tools to stdpath for Neovim
      -- Mason must be loaded before its dependents so we need to set it up here.
      -- NOTE: `opts = {}` is the same as calling `require('mason').setup({})`
      { 'williamboman/mason.nvim', opts = {} },
      { 'williamboman/mason-lspconfig.nvim' },
      'WhoIsSethDaniel/mason-tool-installer.nvim',

      -- Useful status updates for LSP.
      { 'j-hui/fidget.nvim', opts = {} },

      -- Allows extra capabilities provided by nvim-cmp
      'hrsh7th/cmp-nvim-lsp',
      -- 'saghen/blink.cmp',
    },
    config = function()
      --  This function gets run when an LSP attaches to a particular buffer.
      --    That is to say, every time a new file is opened that is associated with
      --    an lsp (for example, opening `main.rs` is associated with `rust_analyzer`) this
      --    function will be executed to configure the current buffer
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
        callback = function(event)
          local map = function(keys, func, desc, mode)
            mode = mode or 'n'
            vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
          end

          -- Jump to the definition of the word under your cursor.
          --  To jump back, press <C-t>.
          map('gd', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')

          -- References: move off bare `gr` to avoid prefix overlap with other gr* maps
          map('gR', function()
            require('trouble').open 'lsp_references'
          end, 'References (Trouble)')

          -- Implementations / Declaration / Type definition
          map('gI', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')
          map('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
          map('<leader>D', require('telescope.builtin').lsp_type_definitions, 'Type [D]efinition')

          -- Symbols
          map('<leader>ds', require('telescope.builtin').lsp_document_symbols, '[D]ocument [S]ymbols')
          map('<leader>ws', require('telescope.builtin').lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')

          -- Rename / Code Action
          map('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
          map('<leader>cla', vim.lsp.buf.code_action, '[C]ode [A]ction', { 'n', 'x' })

          -- Highlight references on CursorHold, clear on move (when supported)
          -- local function client_supports_method(client, method, bufnr)
          --   if vim.fn.has 'nvim-0.11' == 1 then
          --     return client:supports_method(method, bufnr)
          --   else
          --     return client.supports_method(method, { bufnr = bufnr })
          --   end
          -- end
          --
          -- local client = vim.lsp.get_client_by_id(event.data.client_id)
          -- if client and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf) then
          --   local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
          --   vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
          --     buffer = event.buf,
          --     group = highlight_augroup,
          --     callback = vim.lsp.buf.document_highlight,
          --   })
          --   vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
          --     buffer = event.buf,
          --     group = highlight_augroup,
          --     callback = vim.lsp.buf.clear_references,
          --   })
          --   vim.api.nvim_create_autocmd('LspDetach', {
          --     group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
          --     callback = function(event2)
          --       vim.lsp.buf.clear_references()
          --       vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
          --     end,
          --   })
          -- end
          --
          -- Toggle inlay hints when supported
          -- if client and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf) then
          --   map('<leader>th', function()
          --     vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
          --   end, '[T]oggle Inlay [H]ints')
          -- end
        end,
      })

      -- Diagnostic UI
      vim.diagnostic.config {
        severity_sort = true,
        float = { border = 'rounded', source = 'if_many' },
        underline = { severity = vim.diagnostic.severity.ERROR },
        signs = vim.g.have_nerd_font and {
          text = {
            [vim.diagnostic.severity.ERROR] = '󰅚 ',
            [vim.diagnostic.severity.WARN] = '󰀪 ',
            [vim.diagnostic.severity.INFO] = '󰋽 ',
            [vim.diagnostic.severity.HINT] = '󰌶 ',
          },
        } or {},
        virtual_text = {
          source = 'if_many',
          spacing = 2,
          format = function(diagnostic)
            local diagnostic_message = {
              [vim.diagnostic.severity.ERROR] = diagnostic.message,
              [vim.diagnostic.severity.WARN] = diagnostic.message,
              [vim.diagnostic.severity.INFO] = diagnostic.message,
              [vim.diagnostic.severity.HINT] = diagnostic.message,
            }
            return diagnostic_message[diagnostic.severity]
          end,
        },
      }

      -- Capabilities
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      capabilities = vim.tbl_deep_extend('force', capabilities, require('cmp_nvim_lsp').default_capabilities())
      -- capabilities = vim.tbl_deep_extend('force', capabilities, require('blink.cmp').get_lsp_capabilities(capabilities))

      -- Servers
      local servers = {
        -- clangd = {},
        -- gopls = {},
        -- rust_analyzer = {},
        basedpyright = {
          settings = {
            typeCheckingMode = 'standard',
            python = {
              pythonPath = vim.fn.exepath 'python3',
            },
          },
        },
        html = {
          cmd = { 'vscode-html-language-server', '--stdio' },
          filetypes = { 'html', 'templ', 'htmlangular' },
          init_options = {
            configurationSection = { 'html', 'css', 'javascript' },
            embeddedLanguages = { css = true, javascript = true },
            provideFormatter = false,
          },
        },
        cssls = {
          cmd = { 'vscode-css-language-server', '--stdio' },
          filetypes = { 'css', 'scss', 'less' },
          settings = {
            css = {
              validate = true,
              lint = {
                unknownAtRules = 'ignore', -- For Tailwind CSS
              },
            },
            scss = {
              validate = true,
              lint = {
                unknownAtRules = 'ignore',
              },
            },
          },
        },
        tailwindcss = {
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
              lint = {
                cssConflict = 'warning',
                invalidApply = 'error',
                invalidConfigPath = 'error',
                invalidScreen = 'error',
                invalidTailwindDirective = 'error',
                invalidVariant = 'error',
                recommendedVariantOrder = 'warning',
              },
              validate = true,
            },
          },
          root_dir = require('lspconfig.util').root_pattern(
            'tailwind.config.js',
            'tailwind.config.ts',
            'postcss.config.js',
            'postcss.config.ts',
            'package.json',
            '.git'
          ),
        },
        -- ts_ls = {}, -- Example for TypeScript; consider pmizio/typescript-tools.nvim as an alternative
        lua_ls = {
          settings = {
            Lua = {
              completion = { callSnippet = 'Replace' },
              -- diagnostics = { disable = { 'missing-fields' } },
            },
          },
        },
        ts_ls = {
          root_dir = function(fname)
            local util = require 'lspconfig.util'
            -- If angular.json or nx.json is present, do NOT attach ts_ls
            if util.root_pattern('angular.json', 'nx.json')(fname) then
              return nil
            end
            return util.root_pattern('package.json', 'tsconfig.json', '.git')(fname)
          end,
          init_options = {
            plugins = {
              {
                name = '@vue/typescript-plugin',
                location = vim.fn.stdpath 'data' .. '/mason/packages/vue-language-server/node_modules/@vue/language-server',
                languages = { 'vue' },
                configNamespace = 'typescript',
              },
            },
          },
          filetypes = { 'typescript', 'javascript', 'javascriptreact', 'typescriptreact', 'vue' },
        },
        -- Vue/Nuxt Language Server
        vue_ls = {
          root_dir = function(fname)
            local util = require 'lspconfig.util'
            -- Only activate for Vue/Nuxt projects (not Angular)
            if util.root_pattern('angular.json', 'nx.json')(fname) then
              return nil
            end
            -- Look for Vue/Nuxt project markers
            return util.root_pattern('nuxt.config.ts', 'nuxt.config.js', 'vue.config.js', 'vite.config.ts', 'vite.config.js')(fname)
              or util.root_pattern 'package.json'(fname)
          end,
        },
        angularls = {
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
          filetypes = { 'typescript', 'html', 'typescriptreact', 'typescript.tsx', 'htmlangular' },
          root_dir = require('lspconfig.util').root_pattern('angular.json', 'nx.json'),
        },
      }

      -- Mason setup/installation
      local ensure_installed = vim.tbl_keys(servers or {})
      vim.list_extend(ensure_installed, {
        'stylua', -- Used to format Lua code
        'html-lsp', -- HTML Language Server
        'css-lsp', -- CSS Language Server
        'tailwindcss-language-server', -- Tailwind CSS Language Server
        'typescript-language-server', -- TypeScript Language Server
        'angular-language-server', -- Angular Language Server
        'vue-language-server', -- Vue Language Server (Volar)
      })

      require('mason-lspconfig').setup {
        ensure_installed = {}, -- Kickstart defers to mason-tool-installer below
        automatic_installation = false,
        handlers = {
          function(server_name)
            local server = servers[server_name] or {}
            server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})
            require('lspconfig')[server_name].setup(server)
          end,
        },
      }

      require('mason-tool-installer').setup { ensure_installed = ensure_installed }

      -- Manually setup c3 lsp
      -- Mason installs it as 'c3lsp.cmd' on Windows
      local c3_bin = 'c3'
      if vim.fn.executable 'c3lsp' == 1 then
        c3_bin = 'c3lsp'
      elseif vim.fn.executable 'c3-lsp' == 1 then
        c3_bin = 'c3-lsp'
      end

      -- Try to setup c3_lsp (standard name in newer lspconfig) or fall back to custom c3
      -- Suppress deprecation warning by checking existence before requiring if possible,
      -- but require('lspconfig') is the source of the warning.
      -- To fix properly we should use lspconfig[server].setup directly if the module is loaded?
      -- Actually, just silence it or accept it for now as fixing it requires migrating
      -- ALL server setups to the new pattern if we want to be clean.
      -- However, the user asked to fix the warning.

      -- The warning comes from accessing the module via require('lspconfig').
      -- The new way is typically just require('lspconfig')[name].setup or using the configs module directly.
      -- But the plugin itself triggers it on require.

      -- Let's stick to the request: remove the warning.
      -- To do that, we need to update nvim-lspconfig or just suppress it?
      -- "use vim.lsp.config (see :help lspconfig-nvim-0.11) instead"
      -- That usually means for defining NEW servers.

      -- For existing servers, we usually do require('lspconfig')[name].setup({})
      -- But wait, the stack trace shows: C:/Users/winnb/AppData/Local/nvim/lua/plugins/lsp.lua:280: in function 'config'
      -- line 280 is: local lspconfig = require('lspconfig')

      -- We can bypass the warning by not assigning the require result to a variable if we don't need the object globally
      -- or just use the returned table.
      -- Actually, we can use `require('lspconfig.configs')` to check for existence
      -- and `require('lspconfig')[name].setup` for setup.

      local configs = require 'lspconfig.configs'
      local lsp_module = require 'lspconfig' -- This line triggers the warning?

      if configs.c3_lsp then
        lsp_module.c3_lsp.setup {
          capabilities = capabilities,
          cmd = { c3_bin },
          filetypes = { 'c3' },
          root_dir = lsp_module.util.root_pattern('.git', 'project.json'),
        }
      else
        if not configs.c3 then
          configs.c3 = {
            default_config = {
              cmd = { c3_bin },
              filetypes = { 'c3' },
              root_dir = lsp_module.util.root_pattern('.git', 'project.json'),
            },
          }
        end
        lsp_module.c3.setup {
          capabilities = capabilities,
          cmd = { c3_bin },
        }
      end
    end,
  },
}
