--- Ensure the Avante sidebar is open before ACP model/mode selectors run.
--- Upstream acp_config_selector calls handle_submit("") on a sidebar object that may
--- exist while closed, which crashes when containers.result is nil.
local M = {}

function M.apply()
  local selector = package.loaded['avante.acp_config_selector']
    or require 'avante.acp_config_selector'

  if selector._nvim_cursor_acp_selector_patched then
    return
  end

  local open_orig = selector.open

  ---@param category string
  ---@param prompt_label string
  function selector.open(category, prompt_label)
    local avante = require 'avante'
    local sidebar = select(1, avante.get(false))

    if not sidebar then
      avante.open_sidebar {}
      sidebar = select(1, avante.get(false))
    elseif not sidebar:is_open() then
      sidebar:open {}
    end

    if not sidebar or not sidebar:is_open() then
      require('avante.utils').warn 'Open the Avante sidebar before selecting ACP model or mode'
      return
    end

    return open_orig(category, prompt_label)
  end

  selector._nvim_cursor_acp_selector_patched = true
end

return M
