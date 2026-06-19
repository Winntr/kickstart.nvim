local cursor_agent = require 'custom.cursor_agent'

return {
  {
    'ThePrimeagen/99',
    init = function()
      require('custom.patches.agentic_acp_transport').apply()
    end,
    config = function()
      local _99 = require '99'
      local CursorCliProvider = require 'custom.patches.99'

      local cwd = vim.uv.cwd()
      local basename = vim.fs.basename(cwd)
      local log_path = vim.fs.joinpath(vim.fn.stdpath 'state', '99', basename .. '.debug.log')

      _99.setup {
        provider = CursorCliProvider,
        model = cursor_agent.MODEL_COMPOSER_25,
        logger = {
          level = _99.INFO,
          type = 'file',
          path = log_path,
          print_on_error = true,
        },
        display_errors = true,
        tmp_dir = './tmp',
        completion = {
          custom_rules = {
            'scratch/custom_rules/',
          },
          source = 'native',
        },
        md_files = {
          'AGENT.md',
        },
      }

      vim.keymap.set('v', '<leader>9v', function()
        _99.visual()
      end, { desc = '99 visual edit' })

      vim.keymap.set('n', '<leader>9x', function()
        _99.stop_all_requests()
      end, { desc = '99 cancel requests' })

      vim.keymap.set('n', '<leader>9s', function()
        _99.search()
      end, { desc = '99 search' })

      vim.keymap.set('n', '<leader>9m', function()
        require('99.extensions.pickers').get_models(nil, function(models, current)
          local items = vim.tbl_map(function(model)
            local prefix = model == current and '● ' or '  '
            return prefix .. model
          end, models)

          vim.ui.select(items, { prompt = '99 model' }, function(choice)
            if not choice then
              return
            end
            local model = choice:gsub('^● ', ''):gsub('^  ', '')
            require('99.extensions.pickers').on_model_selected(model)
          end)
        end)
      end, { desc = '99 select model' })
    end,
  },
}
