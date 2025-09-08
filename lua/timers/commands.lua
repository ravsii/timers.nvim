local duration = require("timers.duration")
local manager = require("timers.manager")
local timer = require("timers.timer")
local ui = require("timers.ui")

local M = {}

local PREFIX = "Timers"

local COMMANDS = {
  Active = PREFIX .. "Active",
  Cancel = PREFIX .. "Cancel",
  CancelAll = PREFIX .. "CancelAll",
  Dashboard = PREFIX .. "Dashboard",
  Create = PREFIX .. "New",
  Start = PREFIX .. "Start",
}

function M.setup()
  vim.api.nvim_create_user_command(COMMANDS.Active, function()
    ui.active_timers()
  end, { nargs = 0 })

  vim.api.nvim_create_user_command(COMMANDS.Cancel, function(opts)
    local id = tonumber(opts.args)
    if id then
      ui.cancel(id)
    else
      ui.cancel()
    end
  end, { nargs = "?" })

  vim.api.nvim_create_user_command(COMMANDS.CancelAll, function()
    ui.cancel_all()
  end, { nargs = 0 })

  vim.api.nvim_create_user_command(COMMANDS.Dashboard, function()
    require("timers.ui.dashboard"):show()
  end, { nargs = 0 })

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

  vim.api.nvim_create_user_command(COMMANDS.Create, function()
    ui.create_timer()
  end, { nargs = 0 })
end

return M
