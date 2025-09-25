---@class Config
local M = {}

---@type Config
local defaults = {
  default_timer = {
    icon = "󱎫",
    log_level = vim.log.levels.INFO,
    message = "Timer Finished!",
    title = "timers.nvim",
  },
  persistent = false,
  dashboard = {
    update_interval = 1000,
    width = 0.8,
    height = 0.8,
    font = "DiamFont",
    fonts = {},
  },
}

---@param opts Config
function M.setup(opts)
  local merged = vim.tbl_deep_extend("force", defaults, opts or {})
  for k, v in pairs(merged) do
    M[k] = v
  end
end

return M
