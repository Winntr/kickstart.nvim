-- Kulala: HTTP client for Neovim
-- Allows making REST, GraphQL, gRPC, and WebSocket requests from .http files
return {
  'mistweaverco/kulala.nvim',
  ft = { 'http', 'rest' },
  keys = {
    { '<leader>Rs', desc = 'HTTP: Send request' },
    { '<leader>Ra', desc = 'HTTP: Send all requests' },
    { '<leader>Rb', desc = 'HTTP: Open scratchpad' },
    { '<leader>Ri', desc = 'HTTP: Inspect current request' },
    { '<leader>Rc', desc = 'HTTP: Copy as cURL' },
    { '<leader>Rt', desc = 'HTTP: Toggle view (body/headers)' },
  },
  init = function()
    -- Register .http filetype
    vim.filetype.add {
      extension = {
        http = 'http',
      },
    }
  end,
  opts = {
    -- Enable global keymaps with <leader>R prefix
    global_keymaps = true,
    global_keymaps_prefix = '<leader>R',
    kulala_keymaps_prefix = '',

    -- Split direction for response window
    split_direction = 'vertical',

    -- Default view (body, headers, headers_body, raw)
    default_view = 'body',

    -- Winbar display (path to request, method)
    default_winbar_panes = { 'body', 'headers', 'headers_body' },

    -- Environment files to look for (in order of priority)
    environment_scope = 'b', -- b = buffer, g = global

    -- Formatters for response body
    formatters = {
      json = { 'jq', '.' },
      xml = { 'xmllint', '--format', '-' },
      html = { 'prettier', '--parser', 'html' },
    },
  },
  config = function(_, opts)
    require('kulala').setup(opts)
  end,
}
