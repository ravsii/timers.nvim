local config = require("timer.config")
local log_file = vim.fn.stdpath("data") .. "/timer.nvim/debug.log"

---@class Debug
local D = {}

---@param s string
function D.log(s)
  if not config.debug then
    return
  end

  local dir = vim.fn.fnamemodify(log_file, ":h")
  vim.fn.mkdir(dir, "p")

  local f = io.open(log_file, "a") -- open in append mode
  if f then
    f:write(s .. "\n") -- append string + newline
    f:close()
  end
end

return D
