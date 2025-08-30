---@class Config
---@field persistent? boolean Save state across Neovim reloads.
---@field default_timer? TimerOpts Default values for new timers.
local M = {}

---@type Config
local defaults = {
  default_timer = {
    icon = "󱎫",
    log_level = vim.log.levels.INFO,
    message = "Timer Finished!",
    title = "timer.nvim",
  },
  persistent = false,
}

---@param opts Config
function M.setup(opts)
  local merged = vim.tbl_deep_extend("force", defaults, opts or {})
  for k, v in pairs(merged) do
    M[k] = v
  end
end

return M
