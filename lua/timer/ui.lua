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
  -- Create scratch buffer
  local buf = vim.api.nvim_create_buf(false, true)
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.8)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  -- Open floating window
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
  })

  local wo = vim.wo[win]
  wo.winfixwidth = true
  wo.winfixheight = true
  wo.number = false
  wo.relativenumber = false
  wo.cursorline = false
  wo.colorcolumn = ""

  -- Function to build centered content from active timers
  local function build_content()
    local lines = {}

    local timers = active_timers_list()
    for _, item in pairs(timers) do
      table.insert(lines, format_item_select(item))
    end

    table.insert(lines, "")
    table.insert(lines, "Press 'q' to quit.")

    -- Center vertically and horizontally
    local top_padding = math.floor((height - #lines) / 2)
    local content = {}
    for _ = 1, top_padding do
      table.insert(content, "")
    end
    for _, line in ipairs(lines) do
      if line == "" then
        table.insert(content, "")
      else
        local left_padding = math.floor((width - #line) / 2)
        table.insert(content, string.rep(" ", left_padding) .. line)
      end
    end

    return content
  end

  -- Timer for background updates
  local timer = vim.uv.new_timer()
  if not timer then
    error("can't create a new background timer")
  end

  timer:start(
    0,
    50,
    vim.schedule_wrap(function()
      if not vim.api.nvim_buf_is_valid(buf) then
        timer:stop()
        timer:close()
        return
      end

      local content = build_content()

      -- Update buffer safely
      vim.bo[buf].modifiable = true
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
      vim.bo[buf].modifiable = false
    end)
  )

  -- Show buffer in current window
  vim.api.nvim_win_set_buf(win, buf)

  -- Quit key
  vim.keymap.set("n", "q", function()
    if timer then
      timer:stop()
      timer:close()
    end
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end, { buffer = buf })
end

return M
