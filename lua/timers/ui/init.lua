local manager = require("timers.manager")

local notify_opts = { icon = "󱎫", title = "timers.nvim" }

---@alias timer_list_item { id: number, t: Timer }
---@alias timer_list timer_list_item[],

---@return timer_list
local function active_timers_list()
  ---@type timer_list
  local timers = {}

  for id, at in pairs(manager.timers()) do
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

-- function M.create()
--   local api = vim.api
--
--   local fields = {
--     { label = "name:", value = "" },
--     { label = "age:", value = "" },
--   }
--
--   -- 1. Create buffer
--   local buf = api.nvim_create_buf(false, true)
--   local lines = {}
--   for _, f in ipairs(fields) do
--     table.insert(lines, f.label .. " ")
--     table.insert(lines, "")
--   end
--   api.nvim_buf_set_lines(buf, 0, -1, false, lines)
--
--   -- 2. Create floating window
--   local win = api.nvim_open_win(buf, true, {
--     relative = "editor",
--     width = 30,
--     height = #fields,
--     row = 5,
--     col = 10,
--     style = "minimal",
--     border = "rounded",
--   })
--
--   -- 3. Track active field
--   local active = 1
--   api.nvim_win_set_cursor(win, { active, #fields[active].label + 1 })
--
--   -- 4. Map up/down to switch fields
--   local function move_field(dir)
--     active = math.max(1, math.min(#fields, active + dir))
--     vim.api.nvim_win_set_cursor(win, { active, #fields[active].label + 1 })
--   end
--
--   vim.keymap.set(
--     "i",
--     "<Down>",
--     function() move_field(2) end,
--     { buffer = buf, noremap = true, silent = true }
--   )
--   vim.keymap.set(
--     "i",
--     "<Up>",
--     function() move_field(-2) end,
--     { buffer = buf, noremap = true, silent = true }
--   )
-- end

---Shows the list of active timers
function M.active_timers()
  if not M._have_active_timers() then
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
function M.cancel(id)
  if not M._have_active_timers() then
    return
  end

  local function cancel(id)
    if manager.cancel(id) then
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
    ---@param item? timer_list_item
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
function M.cancel_all()
  if not M._have_active_timers() then
    return
  end

  manager.cancel_all()
  vim.notify("All timers cancelled", nil, notify_opts)
end

---Returns true if there are any active timers, vim.notify("No active timers")
---otherwise
---@private
---@return boolean
function M._have_active_timers()
  local n = manager.active_timers_num()
  if n <= 0 then
    vim.notify("No active timers", nil, notify_opts)
    return false
  end

  return true
end
return M
