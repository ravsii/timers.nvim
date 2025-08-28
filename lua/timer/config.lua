---@class Config
---@field persistent? boolean Save state across Neovim reloads

local M = {}

---@type Config
M.defaults = {
  persistent = false,
}

return M
