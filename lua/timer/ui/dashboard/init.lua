local config = require("timer.config")
local debug = require("timer.debug")
local fonts = require("timer.ui.dashboard.fonts")
local manager = require("timer")

---@alias lines line[]
---@alias line segment[]
---@alias segment {str: string, hl:string}

---@class DashboardOpts
---@field update_interval integer Interval for dashboard state updates, in ms.

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

---@class Dashboard
---@field selected integer? current position of cursor
local D = {
  selected = nil,
}

local group_dashboard = vim.api.nvim_create_augroup("timer.nvim/dashboard", { clear = true })

function D.show()
  local buf = vim.api.nvim_create_buf(false, true)
  local w, h, r, c = D.calc_size()

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = w,
    height = h,
    row = r,
    col = c,
    style = "minimal",
    border = "rounded",
  })

  local wo = vim.wo[win]
  wo.winfixwidth = true
  wo.winfixheight = true
  wo.number = false
  wo.relativenumber = false
  wo.cursorline = false
  wo.colorcolumn = ""

  -- Timer for background updates
  local timer = vim.uv.new_timer()
  if not timer then
    error("can't create a new background timer")
  end
  --
  timer:start(
    0,
    config.dashboard.update_interval,
    vim.schedule_wrap(function()
      if not vim.api.nvim_buf_is_valid(buf) then
        timer:stop()
        timer:close()
        return
      end
      ---@diagnostic disable-next-line: redefined-local
      local w, h, _, _ = D.calc_size()
      D.draw(buf, w, h)
    end)
  )

  D.draw(buf, w, h)

  -- Show buffer in current window
  vim.api.nvim_win_set_buf(win, buf)
  local c1, c2 = math.floor(w / 2 + 1), math.floor(h / 2)
  vim.api.nvim_win_set_cursor(win, { c2, c1 })

  vim.api.nvim_create_autocmd({ "VimResized", "WinResized" }, {
    group = group_dashboard,
    callback = function()
      if vim.api.nvim_win_is_valid(win) then
        ---@diagnostic disable-next-line: redefined-local
        local w, h, r, c = D.calc_size()
        vim.api.nvim_win_set_config(win, {
          relative = "editor",
          width = w,
          height = h,
          col = c,
          row = r,
        })
        D.draw(buf, w, h)
      end
    end,
  })

  local function destroy()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    vim.api.nvim_clear_autocmds({ group = group_dashboard })
  end

  vim.api.nvim_create_autocmd("WinClosed", { group = group_dashboard, buffer = buf, callback = destroy })
  vim.keymap.set("n", "q", function()
    destroy()
    if timer then
      timer:stop()
      timer:close()
    end
  end, { buffer = buf })

  -- cursor lock
  local last_cursor = vim.api.nvim_win_get_cursor(0)
  vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
    group = group_dashboard,
    callback = function() vim.api.nvim_win_set_cursor(win, last_cursor) end,
  })
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

---@param w integer width
---@param h integer height
function D.draw(buf, w, h)
  local lines = D.build_lines(w, h)
  local ns = vim.api.nvim_create_namespace("dashboard")

  vim.bo[buf].modifiable = true

  -- Build plain text lines
  local ll = {}
  for _, segments in ipairs(lines) do
    local line_text = ""
    for _, seg in ipairs(segments) do
      line_text = line_text .. seg.str
    end
    table.insert(ll, line_text)
  end

  -- Write lines first
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, ll)

  -- Apply highlights
  for i, segments in ipairs(lines) do
    local col = 0
    local line_nr = i - 1
    for _, seg in ipairs(segments) do
      if seg.hl and #seg.str > 0 then
        vim.api.nvim_buf_set_extmark(buf, ns, line_nr, col, {
          end_col = col + #seg.str,
          hl_group = seg.hl,
        })
      end
      col = col + #seg.str
    end
  end

  vim.bo[buf].modifiable = false
end

---Converts a list of strings into lines of segments with the given highlight group.
---@param lines string[]
---@param hl? string
---@return lines
local function into_segments(lines, hl)
  local result = {} ---@type lines
  local hl_str = hl or "" -- ensures hl is string

  for _, s in ipairs(lines) do
    local line = { { str = s, hl = hl_str } } ---@type line
    table.insert(result, line)
  end

  return result
end

local function line_width(line)
  local sum = 0
  for _, segment in ipairs(line) do
    sum = sum + vim.fn.strdisplaywidth(segment.str)
  end
  return sum
end

---Build centered content from active timers
---@param w integer width
---@param h integer height
---@return lines lines
function D.build_lines(w, h)
  -- TODO: refactor this mess

  ---@type lines
  local segments = {}

  local closest = manager.get_closest_timer()
  debug.log(vim.inspect(closest))
  if closest then
    local big_timer = fonts.from_duration(closest:expire_in())

    vim.list_extend(segments, into_segments(big_timer, "Statement"))

    table.insert(segments, {})
    table.insert(segments, {})
  end

  local timers = active_timers_list()
  --- sort by remaining first
  table.sort(timers, function(a, b) return a.t:expire_in():asMilliseconds() < b.t:expire_in():asMilliseconds() end)
  for _, item in pairs(timers) do
    table.insert(segments, { { str = format_item_select(item) } })
  end

  local binds = {
    { key = "k / ", text = "up" },
    { key = "j / ", text = "down" },
    { key = "d", text = "delete" },
    { key = "q", text = "quit" },
  }

  local bindsSegment = {} ---@type line
  for i, bind in ipairs(binds) do
    if i > 1 then
      bindsSegment[#bindsSegment + 1] = { str = " | ", hl = "Comment" }
    end
    bindsSegment[#bindsSegment + 1] = { str = bind.key, hl = "Character" }
    bindsSegment[#bindsSegment + 1] = { str = " - " .. bind.text }
  end

  -- Center vertically and horizontally
  -- TODO: make 1 line of padding from both top and bottom
  local top_padding = math.floor((h - #segments) / 2)
  local content = {} ---@type lines
  for _ = 1, top_padding do
    table.insert(content, {})
  end
  for _, line in ipairs(segments) do
    if line == "" then
      table.insert(content, {})
    else
      local lw = line_width(line)
      local left_padding_chars = string.rep(" ", math.floor((w - lw) / 2))
      table.insert(line, 1, { str = left_padding_chars })
      table.insert(content, line)
    end
  end
  for _ = 1, top_padding - 2 do
    table.insert(content, {})
  end
  local line = bindsSegment
  local lw = line_width(line)
  local left_padding_chars = string.rep(" ", math.floor((w - lw) / 2))
  table.insert(line, 1, { str = left_padding_chars })
  table.insert(content, line)
  table.insert(content, {})

  return content
end

return D
