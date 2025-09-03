local manager = require("timer")

local notify_opts = { icon = "󱎫", title = "timer.nvim" }

---@alias timer_list_item { id: number, t: Timer }
---@alias timer_list timer_list_item[],

---@return timer_list
local function active_timers_list()
  ---@type timer_list
  local timers = {}

  for id, at in pairs(manager.active_timers) do
    table.insert(timers, { id = id, t = at })
  end

  return timers
end

---@param item timer_list_item
---@return string
local function format_item_select(item)
  return "ID: "
    .. item.id
    .. " | "
    .. item.t.icon
    .. " "
    .. item.t.title
    .. ": "
    .. item.t.message
    .. " | Time left: "
    .. item.t:expire_in():into_hms()
end

---@class UI
local M = {}

---Shows the list of active timers
function M.active_timers()
  vim.ui.select(active_timers_list(), { prompt = "Active Timers", format_item = format_item_select }, function() end)
end

---Shows the list of active timers to cancel
function M.cancel()
  vim.ui.select(
    active_timers_list(),
    { prompt = "Select a timer to cancel", format_item = format_item_select },
    ---@param item? timer_list_item
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
