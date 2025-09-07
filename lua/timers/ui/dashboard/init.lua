local config = require("timers.config")
local fonts = require("timers.ui.dashboard.fonts")
local manager = require("timers.manager")
local ui = require("timers.ui")

---@alias lines segments[]
---@alias segments segment[]
---@alias segment {str: string, hl:string}

---@class DashboardOpts
---Interval (in milliseconds) at which the dashboard state is updated.
---@field update_interval integer
---[0,1] for percentage of the screen, (1,∞) for an absolute value.
---@field width number
---[0,1] for percentage of the screen, (1,∞) for an absolute value.
---@field height number

---@private
---@return timer_list timers List of active timers, sorted by expiration
local function active_timers()
  local timers = {} ---@type timer_list

  for id, at in pairs(manager.timers()) do
    table.insert(timers, { id = id, t = at })
  end

  --- sort by remaining first
  table.sort(
    timers,
    function(a, b) return a.t:expire_in():asMilliseconds() < b.t:expire_in():asMilliseconds() end
  )

  return timers
end

---@param timers timer_list list of timers to convert
---@return lines lines lines to output
local function make_timer_segments(timers)
  if #timers == 0 then
    return { { {
      str = "No active timers",
      hl = "Comment",
    } } }
  end

  local segments = {} ---@type segments
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

    table.insert(segments, { { str = str } })
  end

  return segments
end

---@class Dashboard
local D = {
  cursor_position = -1,
  win = nil,
  buf = nil,
  augroup = vim.api.nvim_create_augroup("timers.nvim/dashboard", { clear = true }),
  namespace = vim.api.nvim_create_namespace("timers.nvim/dashboard"),
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
  })

  -- Timer for background updates
  self.timer = vim.uv.new_timer()
  if not self.timer then
    error("can't create a new background timer")
  end

  self.timer:start(0, config.dashboard.update_interval, vim.schedule_wrap(function() D:draw() end))

  -- Show buffer in current window
  vim.api.nvim_win_set_buf(self.win, self.buf)

  vim.api.nvim_create_autocmd({ "VimResized", "WinResized" }, {
    group = self.augroup,
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

  vim.api.nvim_create_autocmd(
    "WinClosed",
    { group = self.augroup, buffer = self.buf, callback = function() D:destroy() end }
  )

  vim.keymap.set("n", "k", function() D:move_cursor(-1) end, { buffer = self.buf })
  vim.keymap.set("n", "<Up>", function() D:move_cursor(-1) end, { buffer = self.buf })
  vim.keymap.set("n", "j", function() D:move_cursor(1) end, { buffer = self.buf })
  vim.keymap.set("n", "<Down>", function() D:move_cursor(1) end, { buffer = self.buf })

  vim.keymap.set("n", "c", function() self:cancel_selected() end, { buffer = self.buf })
  vim.keymap.set("n", "C", ui.cancel_all, { buffer = self.buf })

  vim.keymap.set("n", "q", function() D:destroy() end, { buffer = self.buf })

  -- cursor lock
  vim.api.nvim_create_autocmd({ "CursorMoved" }, {
    group = self.augroup,
    callback = function() D:move_cursor(0) end,
  })
end

---Converts a list of strings into lines of segments with the given highlight group.
---@param lines string[]
---@param hl? string
---@return lines
local function into_segments(lines, hl)
  local result = {} ---@type lines
  local hl_str = hl or "" -- ensures hl is string

  for _, s in ipairs(lines) do
    local line = { { str = s, hl = hl_str } } ---@type segments
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

function D:draw()
  local timers = active_timers()

  local big_timer_segment = {}
  if #timers > 0 then
    big_timer_segment = into_segments(fonts.from_duration(timers[1].t:expire_in()), "Statement")
  end

  local timers_segment = make_timer_segments(timers)

  local binds = {
    { key = "k / ", text = "up" },
    { key = "j / ", text = "down" },
    { key = "c", text = "cancel selected" },
    { key = "C", text = "cancel all" },
    { key = "q", text = "quit" },
  }

  local binds_segment = {} ---@type segments
  for i, bind in ipairs(binds) do
    if i > 1 then
      binds_segment[#binds_segment + 1] = { str = " | ", hl = "Comment" }
    end
    binds_segment[#binds_segment + 1] = { str = bind.key, hl = "Character" }
    binds_segment[#binds_segment + 1] = { str = " - " .. bind.text }
  end

  local w, h = D:size()

  local content_height = #big_timer_segment + #timers_segment

  -- Center vertically and horizontally
  local top_padding = math.floor((h - content_height) / 2)
  local content = {} ---@type lines

  local offset = 1
  for _ = 1, top_padding do
    table.insert(content, {})
    offset = offset + 1
  end

  for _, line in ipairs(big_timer_segment) do
    local lw = line_width(line)
    local left_padding_chars = string.rep(" ", math.floor((w - lw) / 2))
    table.insert(line, 1, { str = left_padding_chars })
    offset = offset + 1
    table.insert(content, line)
  end

  table.insert(content, {})
  offset = offset + 1

  local c_pos = {}
  for i, line in ipairs(timers_segment) do
    local lw = line_width(line)
    local left_padding_chars = string.rep(" ", math.floor((w - lw) / 2))
    table.insert(line, 1, { str = left_padding_chars })
    table.insert(content, line)
    c_pos[i] = { offset + i - 1, #left_padding_chars }
  end

  for _ = 1, top_padding - 3 do
    table.insert(content, {})
  end
  local line = binds_segment
  local lw = line_width(line)
  local left_padding_chars = string.rep(" ", math.floor((w - lw) / 2))
  table.insert(line, 1, { str = left_padding_chars })
  table.insert(content, line)
  table.insert(content, {})

  vim.bo[self.buf].modifiable = true

  -- Build plain text lines
  local ll = {}
  for _, segments in ipairs(content) do
    local line_text = ""
    for _, seg in ipairs(segments) do
      line_text = line_text .. seg.str
    end
    table.insert(ll, line_text)
  end

  -- Write lines first
  vim.api.nvim_buf_set_lines(self.buf, 0, -1, false, ll)
  vim.api.nvim_win_set_cursor(self.win, c_pos[self.cursor_position])

  -- Apply highlights
  for i, segments in ipairs(content) do
    local col = 0
    local line_nr = i - 1
    for _, seg in ipairs(segments) do
      if seg.hl and #seg.str > 0 then
        vim.api.nvim_buf_set_extmark(self.buf, self.namespace, line_nr, col, {
          end_col = col + #seg.str,
          hl_group = seg.hl,
        })
      end
      col = col + #seg.str
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
  local width = config.dashboard.width
  if width < 1 then
    width = math.floor(vim.o.columns * width)
  end

  local statusline_height = vim.o.laststatus > 1 and 1 or 0

  -- Account for additional UI elements if present (e.g., Lualine)
  -- Lualine typically uses `laststatus`, so `statusline_height` often suffices.
  local main_height = vim.o.lines - vim.o.cmdheight - statusline_height

  local height = config.dashboard.height
  if height < 1 then
    height = math.floor(main_height * height)
  end

  local row = math.floor((main_height - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  return width, height, row, col
end

function D:cancel_selected()
  local timers = active_timers()
  if #timers == 0 or self.cursor_position <= 0 then
    return
  end

  ui.cancel(timers[self.cursor_position].id)
end

---Represents a neovim line like direction where to move cursor:
--- - -1 go up
--- - 0 same position;
--- - 1 go down
---@param direction -1|0|1
function D:move_cursor(direction)
  local timers = active_timers()
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
  vim.api.nvim_clear_autocmds({ group = self.augroup })
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

return D
