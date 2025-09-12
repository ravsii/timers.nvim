local M = {}

---@param opts Config
function M.setup(opts)
  require("timers.config").setup(opts or {})
  require("timers.commands").setup()
  require("timers.autocmd").setup()
  require("timers.manager").setup()
  require("timers.ui.dashboard_fonts").setup()
end

return M
