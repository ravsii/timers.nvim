local duration = require("timer.duration")
local manager = require("timer")
local timer = require("timer.timer")

local M = {}

local COMMANDS = {
  Start = "TimerStart",
  Stop = "TimerStop",
  Cancel = "TimerCancel",
  CancelAll = "TimerCancelAll",
}

function M.setup()
  vim.api.nvim_create_user_command(COMMANDS.Start, function(opts)
    local args = opts.args
    local i = args:find("%s")

    local duration_str, message
    if i then
      duration_str = args:sub(1, i - 1)
      message = args:sub(i + 1)
    else
      duration_str = args
    end

    local d = duration.parse_format(duration_str)
    local t = timer.new(d, { message = message })
    manager.start_timer(t)
  end, { nargs = "+" })

  vim.api.nvim_create_user_command(COMMANDS.Cancel, function(opts)
    local id = tonumber(opts.args)
    if id then
      manager.cancel(id)
    end
  end, { nargs = 1 })

  vim.api.nvim_create_user_command(COMMANDS.CancelAll, function() M.cancel_all() end, { nargs = 0 })
end

return M
