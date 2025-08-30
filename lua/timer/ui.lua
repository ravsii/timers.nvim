local manager = require("timer")

---@class UI
local M = {}

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
        vim.notify("Timer cancelled", nil, { icon = "󱎫", title = "timer.nvim" })
      end
    end
  )
end

return M
