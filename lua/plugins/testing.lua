return {
  -- Test runner framework with multi-language adapter support
  {
    'nvim-neotest/neotest',
    dependencies = {
      'nvim-neotest/nvim-nio',       -- async I/O (also used by dap-ui)
      'nvim-lua/plenary.nvim',       -- async utilities
      'nvim-treesitter/nvim-treesitter', -- syntax parsing for test discovery
      'antoinemadec/FixCursorHold.nvim', -- fix CursorHold performance

      -- Language adapters
      'nvim-neotest/neotest-python',     -- pytest / unittest
      'nvim-neotest/neotest-jest',       -- Jest (JS/TS)
      'marilari88/neotest-vitest',       -- Vitest (JS/TS)
    },
    keys = {
      {
        '<leader>dtt',
        function() require('neotest').run.run() end,
        desc = '[t]est nearest',
      },
      {
        '<leader>dtf',
        function() require('neotest').run.run(vim.fn.expand '%') end,
        desc = '[t]est [f]ile',
      },
      {
        '<leader>dts',
        function() require('neotest').run.run(vim.fn.getcwd()) end,
        desc = '[t]est [s]uite (cwd)',
      },
      {
        '<leader>dto',
        function() require('neotest').output_panel.toggle() end,
        desc = '[t]est [o]utput panel',
      },
      {
        '<leader>dtS',
        function() require('neotest').summary.toggle() end,
        desc = '[t]est [S]ummary',
      },
    },
    config = function()
      require('neotest').setup {
        adapters = {
          -- Python: pytest by default, falls back to unittest
          require('neotest-python') {
            dap = { justMyCode = false },
            runner = 'pytest',
          },

          -- Jest: matches common JS/TS project layouts
          require('neotest-jest') {
            jestCommand = 'npx jest',
            jestConfigFile = function()
              -- Walk up to find the nearest jest config
              local file = vim.fn.expand '%:p'
              local root = vim.fn.fnamemodify(file, ':h')
              local configs = { 'jest.config.ts', 'jest.config.js', 'jest.config.mjs' }
              for _ = 1, 5 do
                for _, cfg in ipairs(configs) do
                  if vim.fn.filereadable(root .. '/' .. cfg) == 1 then
                    return root .. '/' .. cfg
                  end
                end
                root = vim.fn.fnamemodify(root, ':h')
              end
            end,
            env = { CI = 'true' },
            cwd = function()
              return vim.fn.getcwd()
            end,
          },

          -- Vitest: matches vite-based projects
          require('neotest-vitest'),
        },

        -- Open output automatically on test failure
        output = {
          open_on_run = 'short',
        },

        -- Inline diagnostics in the gutter
        diagnostic = {
          enabled = true,
        },

        -- Status icons in the sign column
        status = {
          enabled = true,
          signs = true,
          virtual_text = false,
        },
      }
    end,
  },

  -- Coverage display: reads lcov/cobertura reports and highlights covered lines
  {
    'andythigpen/nvim-coverage',
    dependencies = { 'nvim-lua/plenary.nvim' },
    keys = {
      {
        '<leader>dtc',
        function() require('coverage').toggle() end,
        desc = '[t]est [c]overage toggle',
      },
      {
        '<leader>dtC',
        function() require('coverage').load(true) end,
        desc = '[t]est [C]overage load report',
      },
    },
    config = function()
      require('coverage').setup {
        -- Auto-load coverage data when available
        auto_reload = true,
        -- Highlight groups for covered / uncovered / partial lines
        highlights = {
          covered   = { fg = '#44b677' },
          uncovered = { fg = '#dd5555' },
          partial   = { fg = '#d19a66' },
        },
        signs = {
          covered   = { hl = 'CoverageCovered',   text = '▎' },
          uncovered = { hl = 'CoverageUncovered', text = '▎' },
          partial   = { hl = 'CoveragePartial',   text = '▎' },
        },
        -- Language-specific report paths
        lang = {
          python = {
            coverage_file = '.coverage',
            coverage_command = 'coverage json --fail-under=0 -q -o -',
          },
          javascript = { coverage_file = 'coverage/lcov.info' },
          typescript = { coverage_file = 'coverage/lcov.info' },
        },
      }
    end,
  },
}
