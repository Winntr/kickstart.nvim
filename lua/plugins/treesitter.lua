return {
  {
    'nvim-treesitter/nvim-treesitter',
    -- branch = 'master',
    lazy = false,
    dev = false,
    dependencies = {
      {
        'nvim-treesitter/nvim-treesitter-textobjects',
        dev = false,
        enabled = true,
      },
    },
    build = ':TSUpdate',
    config = function()
      ---@diagnostic disable-next-line: missing-fields

      local ok_configs, configs = pcall(require, 'nvim-treesitter.configs')
      if not ok_configs or not configs then
        return
      end

      configs.setup {
        auto_install = false,
        ensure_installed = {
          'python',
          'markdown',
          'markdown_inline',
          'bash',
          'yaml',
          'lua',
          'vim',
          'query',
          'vimdoc',
          'html',
          'css',
          'dot',
          'angular',
          'javascript',
          'mermaid',
          'typescript',
          'http', -- For kulala.nvim HTTP files
          'json', -- For kulala.nvim response formatting
        },
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = false,
        },
        indent = {
          enable = true,
        },
        incremental_selection = {
          enable = true,
          keymaps = {
            init_selection = 'gnn',
            node_incremental = 'grn',
            scope_incremental = 'grc',
            node_decremental = 'grm',
          },
        },
        textobjects = {
          select = {
            enable = true,
            lookahead = true,
            keymaps = {
              -- You can use the capture groups defined in textobjects.scm
              ['af'] = '@function.outer',
              ['if'] = '@function.inner',
              ['ac'] = '@class.outer',
              ['ic'] = '@class.inner',
              -- Code blocks (for Jupyter notebooks / markdown)
              ['ab'] = '@code_cell.outer',
              ['ib'] = '@code_cell.inner',
            },
          },
          move = {
            enable = true,
            set_jumps = true, -- whether to set jumps in the jumplist
            goto_next_start = {
              [']m'] = '@function.outer',
              [']]'] = '@class.inner',
              [']b'] = '@code_cell.outer', -- next code block
            },
            goto_next_end = {
              [']M'] = '@function.outer',
              [']['] = '@class.outer',
              [']B'] = '@code_cell.outer', -- end of next code block
            },
            goto_previous_start = {
              ['[m'] = '@function.outer',
              ['[['] = '@class.inner',
              ['[b'] = '@code_cell.outer', -- previous code block
            },
            goto_previous_end = {
              ['[M'] = '@function.outer',
              ['[]'] = '@class.outer',
              ['[B'] = '@code_cell.outer', -- end of previous code block
            },
          },
          swap = {
            enable = true,
            swap_next = {
              ['<leader>sbl'] = '@code_cell.outer', -- swap code block with next
            },
            swap_previous = {
              ['<leader>sbh'] = '@code_cell.outer', -- swap code block with previous
            },
          },
        },
      }
    end,
  },
}
