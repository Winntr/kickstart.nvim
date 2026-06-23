--- Guard render-markdown treesitter parse against stale nodes during streaming buffers.
local M = {}

function M.apply()
  local ok, View = pcall(require, 'render-markdown.request.view')
  if not ok or View._treesitter_guard then
    return
  end

  View._treesitter_guard = true

  ---@diagnostic disable-next-line: duplicate-set-field
  function View:parse(parser, callback)
    for _, range in ipairs(self.ranges) do
      if not pcall(parser.parse, parser, range) then
        callback()
        return
      end
    end
    callback()
  end
end

return M
