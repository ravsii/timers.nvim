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
    .. item.t:remaining():into_hms()
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

function M.fullscreen()
  local buf = vim.api.nvim_create_buf(false, false)
  local win = vim.api.nvim_get_current_win()

  local timer = vim.uv.new_timer()
  if not timer then
    error("can't create a new background timer")
  end

  timer:start(
    0,
    1000,
    vim.schedule_wrap(function()
      if not vim.api.nvim_buf_is_valid(buf) then
        timer:stop()
        timer:close()
        return
      end

      local lines = {}
      for _, item in pairs(active_timers_list()) do
        table.insert(lines, format_item_select(item))
      end

      table.insert(lines, "")
      table.insert(lines, "Press 'q' to quit.")
      local width, height = vim.o.columns, vim.o.lines
      local top_padding = math.floor((height - #lines) / 2)
      local content = {}
      for _ = 1, top_padding do
        table.insert(content, "")
      end
      for _, line in ipairs(lines) do
        local left_padding = math.floor((width - #line) / 2)
        table.insert(content, string.rep(" ", left_padding) .. line)
      end

      vim.bo[buf].modifiable = true
      vim.notify("1")
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
      vim.bo[buf].modifiable = false
    end)
  )

  vim.api.nvim_win_set_buf(win, buf)

  vim.keymap.set("n", "q", function()
    timer:stop()
    timer:close()
    vim.api.nvim_buf_delete(buf, { force = true })
  end, { buffer = buf })
end

return M
