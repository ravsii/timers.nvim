local M = {}

function M.closest_timer()
  local t = require('timer').get_closest_timer()
  if t ~= nil then
    return t:remaining():into_hms() or ''
  end
  return ''
end

return M
