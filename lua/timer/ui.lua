local manager = require("timer")

---@class UI
local M = {}

local notify_opts = { icon = "󱎫", title = "timer.nvim" }

---Shows the list of active timers
function M.active_timers()
  local timers = {} ---@type string[]

  for _, at in pairs(manager.active_timers) do
    table.insert(
      timers,
      at.icon .. " " .. at.title .. ": " .. at.message .. " | Time left: " .. at:remaining():into_hms()
    )
  end

  vim.ui.select(timers, { prompt = "Active Timers" }, function() end)
end

---Shows the list of active timers to cancel
function M.cancel()
  ---@alias timerListItem { id: number, t: Timer }
  ---@alias timerList timerListItem[],
  ---@type timerList
  local timers = {}

  for id, at in pairs(manager.active_timers) do
    table.insert(timers, { id = id, t = at })
  end

  vim.ui.select(
    timers,
    {
      prompt = "Select a timer to cancel",
      ---@param item timerListItem
      ---@return string
      format_item = function(item)
        return "ID: "
          .. item.id
          .. " | "
          .. item.t.icon
          .. " "
          .. item.t.title
          .. ": "
          .. item.t.message
          .. " | Time left: "
          .. item.t:remaining():into_hms()
      end,
    },
    ---@param item? timerListItem
    function(item)
      if item == nil then
        return
      end

      if manager.cancel(item.id) then
        vim.notify("Timer cancelled", nil, notify_opts)
      end
    end
  )
end

---Copy of TimerManager.cancel_all, but also gives a feedback message, if there
---were any timers
---@see TimerManager.cancel_all
function M.cancel_all()
  local n = manager.active_timers_num()
  if n > 0 then
    manager.cancel_all()
    vim.notify("All timers cancelled", nil, notify_opts)
  else
    vim.notify("No active timers", nil, notify_opts)
  end
end

return M
