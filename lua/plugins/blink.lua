return {
  {
    'saghen/blink.cmp',
    version = '1.*',
    event = { 'InsertEnter', 'CmdlineEnter' },
    dependencies = {
      'saghen/blink.compat',
      'moyiz/blink-emoji.nvim',
      'L3MON4D3/LuaSnip',
      'rafamadriz/friendly-snippets',
    },
    opts = {
      keymap = {
        preset = 'super-tab',
        ['<C-y>'] = {}, -- copilot.lua ghost text accept
        ['<C-CR>'] = {
          function(cmp)
            if cmp.is_menu_visible() then
              return cmp.accept()
            end
            return false
          end,
          'fallback',
        },
      },
      appearance = {
        nerd_font_variant = 'mono',
      },
      snippets = {
        preset = 'luasnip',
      },
      completion = {
        ghost_text = { enabled = false },
        list = {
          selection = {
            preselect = function(ctx)
              return not require('blink.cmp').snippet_active({ direction = 1 })
            end,
          },
        },
      },
      signature = { enabled = true },
      sources = {
        default = { 'lsp', 'path', 'snippets', 'buffer', 'emoji' },
        per_filetype = {
          sql = { 'lsp', 'path', 'snippets', 'buffer', 'emoji' },
          mysql = { 'lsp', 'path', 'snippets', 'buffer', 'emoji' },
          plsql = { 'lsp', 'path', 'snippets', 'buffer', 'emoji' },
          pgsql = { 'lsp', 'path', 'snippets', 'buffer', 'emoji' },
        },
        providers = {
          avante_commands = {
            name = 'avante_commands',
            module = 'blink.compat.source',
            score_offset = 90,
          },
          avante_files = {
            name = 'avante_files',
            module = 'blink.compat.source',
            score_offset = 100,
          },
          avante_mentions = {
            name = 'avante_mentions',
            module = 'blink.compat.source',
            score_offset = 1000,
          },
          avante_shortcuts = {
            name = 'avante_shortcuts',
            module = 'blink.compat.source',
            score_offset = 1000,
          },
          emoji = {
            name = 'Emoji',
            module = 'blink-emoji',
            score_offset = 50,
            min_keyword_length = 0,
            opts = {
              insert = true,
            },
          },
        },
      },
    },
    config = function(_, opts)
      local ok_cmp, cmp_mod = pcall(require, 'cmp')
      if ok_cmp and type(cmp_mod) == 'table' then
        cmp_mod.ConfirmBehavior = cmp_mod.ConfirmBehavior or { Insert = 'insert', Replace = 'replace' }
      else
        package.loaded.cmp = {
          ConfirmBehavior = { Insert = 'insert', Replace = 'replace' },
        }
      end

      local augroup = vim.api.nvim_create_augroup('blink-copilot-coexist', { clear = true })
      vim.api.nvim_create_autocmd('User', {
        group = augroup,
        pattern = 'BlinkCmpMenuOpen',
        callback = function()
          vim.b.copilot_suggestion_hidden = true
        end,
      })
      vim.api.nvim_create_autocmd('User', {
        group = augroup,
        pattern = 'BlinkCmpMenuClose',
        callback = function()
          vim.b.copilot_suggestion_hidden = false
        end,
      })

      require('blink.cmp').setup(opts)
    end,
  },
}
