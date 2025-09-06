---@class Config
---@field persistent? boolean Save state across Neovim reloads.
---@field default_timer? TimerOpts Default values for new timers.
---@field dashboard? DashboardOpts
---@field debug? boolean Enables debug logging to {data}/timers.nvim/debug.log
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
  },
  debug = false,
}

---@param opts Config
function M.setup(opts)
  local merged = vim.tbl_deep_extend("force", defaults, opts or {})
  for k, v in pairs(merged) do
    M[k] = v
  end
end

return M
