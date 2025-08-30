---@class Config
---@field persistent? boolean Save state across Neovim reloads.
---@field default_title? string Default title for all timers.
---@field default_icon? string Default icon for all timers. No icon if not passed.
local M = {}

---@type Config
M.defaults = {
  persistent = false,
}

---@param opts Config
function M:setup(opts) self = vim.tbl_deep_extend("force", M.defaults, opts or {}) end

return M
