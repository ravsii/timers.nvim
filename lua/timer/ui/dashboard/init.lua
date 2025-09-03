local config = require("timer.config")
local fonts = require("timer.ui.dashboard.fonts")
local manager = require("timer")

---@class DashboardOpts
---@field update_interval integer Interval for dashboard state updates, in ms.

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

local D = {}

local resize_group = vim.api.nvim_create_augroup("timer/resize", { clear = true })

function D.show()
  local buf = vim.api.nvim_create_buf(false, true)
  local w, h, r, c = D.calc_size()

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = w,
    height = h,
    row = r,
    col = c,
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
    ---@type string[]
    local lines = {}

    local closest = manager.get_closest_timer()
    if closest then
      local big_timer = fonts.from_duration(closest:remaining())

      vim.list_extend(lines, big_timer)
      vim.print(lines)

      table.insert(lines, "")
      table.insert(lines, "")
    end

    local timers = active_timers_list()
    for _, item in pairs(timers) do
      table.insert(lines, format_item_select(item))
    end

    table.insert(lines, "")
    table.insert(lines, "Press 'q' to quit.")

    local w, h, _, _ = D.calc_size()

    -- Center vertically and horizontally
    local top_padding = math.floor((h - #lines) / 2)
    local content = {}
    for _ = 1, top_padding do
      table.insert(content, "")
    end
    for _, line in ipairs(lines) do
      if line == "" then
        table.insert(content, "")
      else
        local left_padding = math.floor((w - vim.fn.strdisplaywidth(line)) / 2)
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

  local function draw()
    local content = build_content()
    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
    vim.bo[buf].modifiable = false
  end

  timer:start(
    0,
    config.dashboard.update_interval,
    vim.schedule_wrap(function()
      if not vim.api.nvim_buf_is_valid(buf) then
        timer:stop()
        timer:close()
        return
      end
      draw()
    end)
  )

  -- Show buffer in current window
  vim.api.nvim_win_set_buf(win, buf)

  vim.api.nvim_create_autocmd("VimResized", {
    group = resize_group,
    callback = function()
      if vim.api.nvim_win_is_valid(win) then
        local w, h, r, c = D.calc_size()
        vim.api.nvim_win_set_config(win, {
          relative = "editor",
          width = w,
          height = h,
          col = c,
          row = r,
        })
        draw()
      end
    end,
  })

  -- Quit key
  vim.keymap.set("n", "q", function()
    if timer then
      timer:stop()
      timer:close()
    end
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    vim.api.nvim_clear_autocmds({ group = resize_group })
  end, { buffer = buf })
end

---@return integer width
---@return integer height
---@return integer row
---@return integer col
function D.calc_size()
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.8)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  return width, height, row, col
end

return D
