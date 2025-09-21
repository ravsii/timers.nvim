local config = require("timers.config")
local fonts = require("timers.ui.dashboard_fonts")
local manager = require("timers.manager")
local ui = require("timers.ui")
local utils = require("timers.ui.utils")

---@alias Lines Segments[]
---@alias Segments Segment[]
---@alias Segment {str: string, hl:string}

---@class DashboardOpts
---Interval (in milliseconds) at which the dashboard state is updated.
---@field update_interval? integer
---[0,1] for percentage of the screen, (1,∞) for an absolute value.
---@field width? number
---[0,1] for percentage of the screen, (1,∞) for an absolute value.
---@field height? number
---Font to use. Available values: DiamFont, Terrace, tmplr.
---Or, you can provide a custom font using "fonts" field and use its name.
---@field font? "DiamFont"|"Terrace"|"tmplr"|string
---@field fonts? FontTable

local augroup = vim.api.nvim_create_augroup("timers.nvim/dashboard", { clear = true })
local namespace = vim.api.nvim_create_namespace("timers.nvim/dashboard")

---@class Dashboard
local D = {
  win = nil,
  buf = nil,

  ---Represents current cursor position. If out of bounds, it will be corrected
  ---to the nearest available position.
  ---@alias CursorPos integer
  ---@type CursorPos
  cursor_position = -1,
  ---@type { [CursorPos]: { id: TimerID, pos: integer[] } }
  cursor_positions = {},
}

function D:show()
  self:reset()

  self.buf = vim.api.nvim_create_buf(false, true)
  local w, h, r, c = D:size()
  self.win = vim.api.nvim_open_win(self.buf, true, {
    relative = "editor",
    width = w,
    height = h,
    row = r,
    col = c,
    style = "minimal",
    border = "rounded",
    title = " Dashboard ",
    title_pos = "center",
  })

  -- Timer for background updates
  self.timer = vim.uv.new_timer()
  if not self.timer then
    error("can't create a new background timer")
  end

  self.timer:start(
    0,
    config.dashboard.update_interval,
    vim.schedule_wrap(function()
      D:draw()
    end)
  )

  -- Show buffer in current window
  vim.api.nvim_win_set_buf(self.win, self.buf)

  vim.api.nvim_create_autocmd({ "VimResized", "WinResized" }, {
    group = augroup,
    callback = function()
      if vim.api.nvim_win_is_valid(self.win) then
        ---@diagnostic disable-next-line: redefined-local
        local w, h, r, c = D:size()
        vim.api.nvim_win_set_config(self.win, {
          relative = "editor",
          width = w,
          height = h,
          col = c,
          row = r,
        })
        D:draw()
      end
    end,
  })

  vim.api.nvim_create_autocmd("WinClosed", {
    group = augroup,
    buffer = self.buf,
    callback = function()
      D:destroy()
    end,
  })

  vim.keymap.set("n", "k", function()
    D:move_cursor(-1)
  end, { buffer = self.buf })
  vim.keymap.set("n", "<Up>", function()
    D:move_cursor(-1)
  end, { buffer = self.buf })
  vim.keymap.set("n", "j", function()
    D:move_cursor(1)
  end, { buffer = self.buf })
  vim.keymap.set("n", "<Down>", function()
    D:move_cursor(1)
  end, { buffer = self.buf })

  vim.keymap.set("n", "c", function()
    self:cancel_selected()
  end, { buffer = self.buf })
  vim.keymap.set("n", "C", ui.cancel_all, { buffer = self.buf })

  vim.keymap.set("n", "q", function()
    D:destroy()
  end, { buffer = self.buf })

  -- cursor lock
  vim.api.nvim_create_autocmd({ "CursorMoved" }, {
    group = augroup,
    callback = function()
      D:move_cursor(0)
    end,
  })
end

local binds = {
  {
    { key = "k / ", text = "up" },
    { key = "j / ", text = "down" },
    { key = "r", text = "resume" },
    { key = "p", text = "pause" },
    { key = "c", text = "cancel" },
  },
  {
    { key = "C", text = "cancel all" },
    { key = "q", text = "quit" },
  },
}

---Converts a list of strings into lines of segments with the given highlight group.
---@param lines string[]
---@param hl? string
---@return Lines
local function into_segments(lines, hl)
  local result = {} ---@type Lines
  local hl_str = hl or "" -- ensures hl is string

  for _, s in ipairs(lines) do
    local line = { { str = s, hl = hl_str } } ---@type Segments
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

---Draws a dashboard.
---The general idea is pretty simple, we build multiple segments in a single
---"content" storage, then calculate paddings based on amount of content and
---then draw everything.
---@private
function D:draw()
  local timers = self.active_timers()

  local big_timer_segment = {}
  if #timers > 0 then
    local big_timer = fonts.from_duration(timers[1].t:expire_in(), config.dashboard.font)
    big_timer_segment = into_segments(big_timer, "Statement")
  end

  local timers_segment = self.make_timer_segments(timers)

  local binds_segment = {} ---@type Lines
  for _, bind_line in pairs(binds) do
    local segment = {} ---@type Segments
    for i, bind in ipairs(bind_line) do
      if i > 1 then
        segment[#segment + 1] = { str = " | ", hl = "Comment" }
      end
      segment[#segment + 1] = { str = "[" .. bind.key .. "]", hl = "Character" }
      segment[#segment + 1] = { str = " " .. bind.text }
    end
    binds_segment[#binds_segment + 1] = segment
  end

  local w, h = D:size()
  local content = {} ---@type Lines

  for _, line in ipairs(big_timer_segment) do
    local lw = line_width(line)
    local left_padding_chars = string.rep(" ", math.floor((w - lw) / 2))
    table.insert(line, 1, { str = left_padding_chars })
    table.insert(content, line)
  end

  self.cursor_positions = {}
  for i, line in ipairs(timers_segment) do
    local lw = line_width(line)
    local left_padding_chars = string.rep(" ", math.floor((w - lw) / 2))
    table.insert(line, 1, { str = left_padding_chars })
    table.insert(content, line)
    if #timers > 0 then
      self.cursor_positions[i] = {
        id = timers[i].id,
        pos = { #content, #left_padding_chars },
      }
    end
  end

  for _, line in pairs(binds_segment) do
    local lw = line_width(line)
    local left_padding_chars = string.rep(" ", math.floor((w - lw) / 2))
    table.insert(line, 1, { str = left_padding_chars })
    table.insert(content, line)
  end

  local max_height = h - #binds
  local content_height = #content - #binds

  -- how many empty rows we can add
  -- "-1" is extra padding from the bottom for binds
  local total_padding = max_height - content_height - 1
  local base = math.floor(total_padding / 3)
  local extra = total_padding % 3 -- distribute remainder

  local padding_top = base
  local padding_middle = base
  local padding_bottom = base

  if extra >= 1 then
    padding_top = padding_top + 1
  end
  if extra >= 2 then
    padding_middle = padding_middle + 1
  end

  for _ = 1, padding_bottom do
    table.insert(content, #content - #binds + 1, {})
  end
  for _ = 1, padding_middle do
    table.insert(content, #big_timer_segment + 1, {})
  end
  for _ = 1, padding_top do
    table.insert(content, 1, {})
  end

  vim.bo[self.buf].modifiable = true

  -- Build plain text lines
  local ll = {}
  for _, segments in ipairs(content) do
    local line_text = ""
    for _, seg in ipairs(segments) do
      line_text = line_text .. (seg.str or "")
    end
    table.insert(ll, line_text)
  end

  -- Write lines first
  vim.api.nvim_buf_set_lines(self.buf, 0, -1, false, ll)
  if #self.cursor_positions > 0 then
    vim.api.nvim_win_set_cursor(self.win, self.cursor_positions[self.cursor_position].pos)
  else
    vim.api.nvim_win_set_cursor(self.win, { 1, 0 })
  end

  -- Apply highlights
  for i, segments in ipairs(content) do
    local col = 0
    local line_nr = i - 1
    for _, seg in ipairs(segments) do
      if seg.hl and #seg.str > 0 then
        vim.api.nvim_buf_set_extmark(self.buf, namespace, line_nr, col, {
          end_col = col + #seg.str,
          hl_group = seg.hl,
        })
      end
      col = col + (seg.str and #seg.str or 0)
    end
  end

  vim.bo[self.buf].modifiable = false
end

---Returns size and start coordinates.
---@return integer width
---@return integer height
---@return integer row
---@return integer col
function D:size()
  return utils.calc_popup_size(config.dashboard.width, config.dashboard.height)
end

function D:cancel_selected()
  local timers = self.active_timers()
  if #timers == 0 or self.cursor_position <= 0 then
    return
  end

  ui.cancel(timers[self.cursor_position].id)

  if self.cursor_position == #timers then
    D:move_cursor(-1)
  end
end

---Represents a neovim line like direction where to move cursor:
--- - -1 go up
--- - 0 same position;
--- - 1 go down
---@param direction -1|0|1
function D:move_cursor(direction)
  local timers = self.active_timers()
  if #timers == 0 then
    self.cursor_position = -1
  end

  self.cursor_position = math.max(1, math.min(#timers, self.cursor_position + direction)) -- clamp
  self:draw()
end

function D:destroy()
  if self.win and vim.api.nvim_win_is_valid(self.win) then
    vim.api.nvim_win_close(self.win, true)
  end
  vim.api.nvim_clear_autocmds({ group = augroup })
  D:reset()
end

function D:reset()
  self.buf = nil
  self.win = nil
  self.cursor_position = -1
  if self.timer and not self.timer:is_closing() then
    self.timer:stop()
    self.timer:close()
    self.timer = nil
  end
end

---@private
---@return TimersList timers List of active timers, sorted by expiration
function D.active_timers()
  local timers = {} ---@type TimersList

  for id, at in pairs(manager.timers()) do
    table.insert(timers, { id = id, t = at })
  end

  --- sort by remaining first
  table.sort(timers, function(a, b)
    return a.t:expire_in():asMilliseconds() < b.t:expire_in():asMilliseconds()
  end)

  return timers
end

---@private
---@param timers TimersList list of timers to convert
---@return Lines lines lines to output
function D.make_timer_segments(timers)
  if #timers == 0 then
    return { { {
      str = "No active timers",
      hl = "Comment",
    } } }
  end

  local segments = {} ---@type Segments
  for _, item in pairs(timers) do
    local str = "ID: "
      .. item.id
      .. " | "
      .. item.t.icon
      .. " "
      .. item.t.title
      .. ": "
      .. item.t.message
      .. " | Time left: "
      .. item.t:expire_in():into_hms()
      .. (item.t.paused_at and " (paused)" or "")

    table.insert(segments, { { str = str } })
  end

  return segments
end

return D
