local manager = require("timers.manager")

local notify_opts = { icon = "󱎫", title = "timers.nvim" }

---@alias TimersListItem { id: number, t: Timer }
---@alias TimersList TimersListItem[],

---@return TimersList
local function active_timers_list()
  ---@type TimersList
  local timers = {}

  for id, at in pairs(manager.timers()) do
    table.insert(timers, { id = id, t = at })
  end

  return timers
end

---@param item TimersListItem
---@return string
local function format_item_select(item)
  return "ID: "
    .. item.id
    .. " | Paused: "
    .. (item.t.paused_at and "" or "")
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
local UI = {}

---Shows the list of active timers
function UI.active_timers()
  if not UI._have_active_timers() then
    return
  end

  vim.ui.select(
    active_timers_list(),
    { prompt = "Active Timers", format_item = format_item_select },
    function() end
  )
end

---Shows the list of active timers to cancel
---@param id integer? if passed, cancels a specific timer
function UI.cancel(id)
  if not UI._have_active_timers() then
    return
  end

  local function cancel(cid)
    if manager.cancel(cid) then
      vim.notify("Timer cancelled", nil, notify_opts)
    end
  end

  if id then
    cancel(id)
    return
  end

  vim.ui.select(
    active_timers_list(),
    { prompt = "Select a timer to cancel", format_item = format_item_select },
    ---@param item? TimersListItem
    function(item)
      if item == nil then
        return
      end

      cancel(item.id)
    end
  )
end

---Copy of TimerManager.cancel_all, but also gives a feedback message, if there
---were any timers
---@see TimerManager.cancel_all
function UI.cancel_all()
  if not UI._have_active_timers() then
    return
  end

  manager.cancel_all()
  vim.notify("All timers cancelled", nil, notify_opts)
end

function UI.create_timer()
  require("timers.ui.create"):create_timer()
end

function UI.dashboard()
  require("timers.ui.dashboard"):show()
end

---Shows the list of active timers to pause.
---@param id integer? if passed, cancels a specific timer
function UI.pause(id)
  if not UI._have_active_timers() then
    return
  end

  local function pause(pid)
    if manager.pause(pid) then
      vim.notify("Timer " .. pid .. " paused", vim.log.levels.INFO, notify_opts)
    end
  end

  if id then
    pause(id)
    return
  end

  vim.ui.select(
    active_timers_list(),
    { prompt = "Select a timer to pause", format_item = format_item_select },
    ---@param item? TimersListItem
    function(item)
      if item == nil then
        return
      end

      pause(item.id)
    end
  )
end

---Returns true if there are any active timers, vim.notify("No active timers")
---otherwise
---@private
---@return boolean
function UI._have_active_timers()
  local n = manager.active_timers_num()
  if n <= 0 then
    vim.notify("No active timers", nil, notify_opts)
    return false
  end

  return true
end
return UI
