-- Jupyter Notebook support for Neovim
-- Provides: code execution, output viewing, ipynb conversion, LSP in code blocks
return {
  -- Molten: Interactive code execution with Jupyter kernels
  {
    'benlubas/molten-nvim',
    version = '^1.0.0', -- use version <2.0.0 to avoid breaking changes
    build = ':UpdateRemotePlugins',
    init = function()
      -- Output display settings
      vim.g.molten_auto_open_output = false -- We'll use keymaps to show output
      vim.g.molten_output_show_more = true
      vim.g.molten_output_virt_lines = true
      vim.g.molten_virt_text_output = true
      vim.g.molten_virt_lines_off_by_1 = true -- Output below ``` delimiter
      vim.g.molten_wrap_output = true

      -- Window styling
      vim.g.molten_output_win_max_height = 20
      vim.g.molten_output_win_border = { '', '━', '', '' }
      vim.g.molten_output_win_style = false
      vim.g.molten_output_win_cover_gutter = true
      vim.g.molten_use_border_highlights = true

      -- No image support for now (Windows compatibility)
      vim.g.molten_image_provider = 'none'

      -- Performance
      vim.g.molten_tick_rate = 200
    end,
    keys = {
      { '<leader>ji', ':MoltenInit<CR>', desc = 'Jupyter: Init kernel' },
      { '<leader>jI', ':MoltenInfo<CR>', desc = 'Jupyter: Info' },
      { '<leader>je', ':MoltenEvaluateOperator<CR>', desc = 'Jupyter: Evaluate operator' },
      { '<leader>jl', ':MoltenEvaluateLine<CR>', desc = 'Jupyter: Evaluate line' },
      { '<leader>jr', ':MoltenReevaluateCell<CR>', desc = 'Jupyter: Re-evaluate cell' },
      { '<leader>jv', ':<C-u>MoltenEvaluateVisual<CR>gv', mode = 'v', desc = 'Jupyter: Evaluate visual' },
      { '<leader>jo', ':noautocmd MoltenEnterOutput<CR>', desc = 'Jupyter: Show/enter output' },
      { '<leader>jh', ':MoltenHideOutput<CR>', desc = 'Jupyter: Hide output' },
      { '<leader>jd', ':MoltenDelete<CR>', desc = 'Jupyter: Delete cell' },
      { '<leader>jx', ':MoltenInterrupt<CR>', desc = 'Jupyter: Interrupt kernel' },
      { '<leader>jR', ':MoltenRestart!<CR>', desc = 'Jupyter: Restart kernel' },
      -- Import/export outputs
      { '<leader>jsi', ':MoltenImportOutput<CR>', desc = 'Jupyter: Import outputs' },
      { '<leader>jse', ':MoltenExportOutput!<CR>', desc = 'Jupyter: Export outputs' },
    },
    config = function()
      -- Auto import/export outputs for .ipynb files
      local augroup = vim.api.nvim_create_augroup('MoltenNotebook', { clear = true })

      -- Track which buffers originated from .ipynb files
      -- (jupytext converts them to .md, so we need to track the original)
      vim.api.nvim_create_autocmd('BufReadPost', {
        group = augroup,
        pattern = '*.ipynb',
        callback = function(args)
          -- Mark this buffer as a notebook
          vim.b[args.buf].is_notebook = true
        end,
      })

      -- Also catch the converted markdown buffer (jupytext creates .md from .ipynb)
      vim.api.nvim_create_autocmd('BufReadPost', {
        group = augroup,
        pattern = '*.md',
        callback = function(args)
          -- Check if this markdown file has a corresponding .ipynb
          local md_path = vim.api.nvim_buf_get_name(args.buf)
          local ipynb_path = md_path:gsub('%.md$', '.ipynb')
          if vim.fn.filereadable(ipynb_path) == 1 then
            vim.b[args.buf].is_notebook = true
            vim.b[args.buf].notebook_path = ipynb_path
          end
        end,
      })

      -- Auto-import outputs when a notebook buffer is fully loaded
      vim.api.nvim_create_autocmd('BufWinEnter', {
        group = augroup,
        pattern = { '*.ipynb', '*.md' },
        callback = function(args)
          if not vim.b[args.buf].is_notebook then
            return
          end
          -- Defer to ensure molten is ready
          vim.defer_fn(function()
            -- Check if molten commands are available (requires :UpdateRemotePlugins)
            if vim.fn.exists ':MoltenInfo' ~= 2 then
              return
            end
            -- Only import if molten has an active kernel for this buffer
            local ok, molten_status = pcall(vim.fn['MoltenStatusLineKernels'])
            if ok and molten_status and molten_status ~= '' then
              pcall(vim.cmd, 'MoltenImportOutput')
            end
          end, 500)
        end,
      })

      -- Auto-export outputs when saving a notebook buffer
      vim.api.nvim_create_autocmd('BufWritePost', {
        group = augroup,
        pattern = { '*.ipynb', '*.md' },
        callback = function(args)
          if not vim.b[args.buf].is_notebook then
            return
          end
          -- Check if molten commands are available (requires :UpdateRemotePlugins)
          if vim.fn.exists ':MoltenInfo' ~= 2 then
            return
          end
          -- Only export if molten has an active kernel
          local ok, molten_status = pcall(vim.fn['MoltenStatusLineKernels'])
          if ok and molten_status and molten_status ~= '' then
            pcall(vim.cmd, 'MoltenExportOutput!')
          end
        end,
      })
    end,
  },

  -- Jupytext: Convert .ipynb files to/from markdown
  {
    'GCBallesteros/jupytext.nvim',
    lazy = false, -- Load immediately to intercept .ipynb files
    config = function()
      require('jupytext').setup {
        style = 'markdown',
        output_extension = 'md',
        force_ft = 'markdown',
      }
    end,
  },

  -- Quarto: LSP features in code blocks + code runner integration
  {
    'quarto-dev/quarto-nvim',
    dependencies = {
      'jmbuhr/otter.nvim', -- You already have this
      'nvim-treesitter/nvim-treesitter',
    },
    ft = { 'quarto', 'markdown' },
    config = function()
      local quarto = require 'quarto'
      quarto.setup {
        lspFeatures = {
          languages = { 'python', 'r', 'julia', 'lua' },
          chunks = 'all',
          diagnostics = {
            enabled = true,
            triggers = { 'BufWritePost' },
          },
          completion = {
            enabled = true,
          },
        },
        codeRunner = {
          enabled = true,
          default_method = 'molten',
        },
      }

      -- Quarto runner keymaps
      local runner = require 'quarto.runner'
      vim.keymap.set('n', '<leader>jc', runner.run_cell, { desc = 'Jupyter: Run cell', silent = true })
      vim.keymap.set('n', '<leader>ja', runner.run_above, { desc = 'Jupyter: Run cell and above', silent = true })
      vim.keymap.set('n', '<leader>jA', runner.run_all, { desc = 'Jupyter: Run all cells', silent = true })
      vim.keymap.set('n', '<leader>jb', runner.run_below, { desc = 'Jupyter: Run cell and below', silent = true })
      vim.keymap.set('v', '<leader>jr', runner.run_range, { desc = 'Jupyter: Run visual range', silent = true })
    end,
  },
}
