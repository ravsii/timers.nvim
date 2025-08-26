local M = {}

---@param d Duration
---@param message? string
function M.start_timer(d, message)
  if message == '' or message == nil then
    message = 'Timer finished!'
  end

  vim.defer_fn(function() vim.notify(message, vim.log.levels.WARN) end, d:asMilliseconds())
end

return M
