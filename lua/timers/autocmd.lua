local manager = require("timers.manager")

local M = {}

local aug = vim.api.nvim_create_augroup("timers.nvim/autocmd", { clear = true })

function M.setup()
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = aug,
    callback = function()
      manager.save_state()
    end,
  })
end

return M
