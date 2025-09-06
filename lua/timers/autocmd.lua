local M = {}

local aug = vim.api.nvim_create_augroup("TimerSaveState", { clear = true })
function M.setup()
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = aug,
    callback = function() M.save_state() end,
  })
end

return M
