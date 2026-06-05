return {
  'joeveiga/ng.nvim',
  lazy = true,
  enabled = function()
    return not vim.g.vscode
  end,
  ft = { 'typescript', 'typescriptreact', 'htmlangular' },
  keys = {
    {
      '<leader>cat',
      function()
        require('ng').goto_template_for_component()
      end,
      desc = 'Go to template for component',
    },
    {
      '<leader>cac',
      function()
        require('ng').goto_component_with_template_file()
      end,
      desc = 'Go to component with template file',
    },
    {
      '<leader>caT',
      function()
        require('ng').get_template_tcb()
      end,
      desc = 'Get template TCB',
    },
  },
}
