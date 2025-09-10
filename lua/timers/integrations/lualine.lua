local manager = require("timers.manager")

local M = {}

function M.closest_timer()
  local t = manager.get_closest_timer()
  if t == nil then
    return ""
  end

  return t:expire_in():into_hms()
end

return M
