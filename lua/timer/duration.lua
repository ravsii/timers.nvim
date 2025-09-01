local unit = require("timer.unit")
---@class Duration
---@field value integer Duration in milliseconds
local Duration = {}
Duration.__index = Duration

---Create a new Duration object
---@param ms? integer duration in milliseconds (default: 0)
---@return Duration
function Duration.from(ms)
  local val = math.max(ms or 0, 0)
  return setmetatable({ value = val }, Duration)
end

---Return value in milliseconds
---@return integer ms milliseconds, suitable for lua functions
function Duration:asMilliseconds() return self.value end

---Return value in seconds
---@return integer seconds
function Duration:asSeconds() return self.value / unit.SECOND end

--- Returns a new Duration representing the result of subtracting `sub` from
--- this duration. This does not modify the current Duration instance.
---@param sub Duration
---@return Duration result
function Duration:sub(sub)
  local val = math.max(self.value - sub.value, 0)
  return Duration.from(val)
end

---Parse a duration string into a Duration object.
---
---Supports integer and fractional values, with units:
--- - `s` for seconds
--- - `m` for minutes
--- - `h` for hours
---
---Values without unit are parsed as milliseconds.
---
---### Examples
---```lua
--- local d1 = Duration.parse("3m")        -- 3 minutes → 180000 ms
--- local d2 = Duration.parse("3.5m")      -- 3 min 30 sec → 210000 ms
--- local d3 = Duration.parse("1.75h")     -- 1 hour 45 min → 6300000 ms
--- local d4 = Duration.parse("45s")       -- 45 seconds → 45000 ms
--- local d5 = Duration.parse("1500")      -- raw milliseconds → 1500 ms
---```
---
---@param str string Go's time.Duration-like format
---@return Duration
function Duration.parse_format(str)
  local self = setmetatable({ value = 0 }, Duration)

  local result = 0
  local curNum, fracNum, fracDiv = 0, 0, 1
  local inFraction = false

  local function addNum(n)
    if inFraction then
      fracNum = fracNum * 10 + n
      fracDiv = fracDiv * 10
    else
      curNum = curNum * 10 + n
    end
  end

  local function addTimeUnit(timeUnit)
    local total = curNum + (fracNum / fracDiv)
    result = result + total * timeUnit
    -- reset state
    curNum, fracNum, fracDiv, inFraction = 0, 0, 1, false
  end

  local cases = {
    ["0"] = function() addNum(0) end,
    ["1"] = function() addNum(1) end,
    ["2"] = function() addNum(2) end,
    ["3"] = function() addNum(3) end,
    ["4"] = function() addNum(4) end,
    ["5"] = function() addNum(5) end,
    ["6"] = function() addNum(6) end,
    ["7"] = function() addNum(7) end,
    ["8"] = function() addNum(8) end,
    ["9"] = function() addNum(9) end,
    ["."] = function() inFraction = true end,
    ["s"] = function() addTimeUnit(unit.SECOND) end,
    ["m"] = function() addTimeUnit(unit.MINUTE) end,
    ["h"] = function() addTimeUnit(unit.HOUR) end,
  }

  for c in str:gmatch(".") do
    (cases[c] or function() error("Unexpected char: " .. c) end)()
  end

  addTimeUnit(unit.MILLISECOND)

  self.value = result
  return self
end

--- Returns a human-readable duration string.
--- Formats based on the duration length:
--- - `HH:MM:SS` for durations of 1 hour or more
--- - `MM:SS` for durations between 1 minute and 1 hour. ss is a
--- number
--- - `XXs` for durations less than 1 minute. x is a number and s
--- represends seconds
---@return string duration
function Duration:into_hms()
  local seconds = self:asSeconds()
  local h = math.floor(seconds / 3600)
  local m = math.floor((seconds % 3600) / 60)
  local s = seconds % 60

  if h > 0 then
    return string.format("%02d:%02d:%02d", h, m, s)
  elseif m > 0 then
    return string.format("%02d:%02d", m, s)
  else
    return string.format("%02ds", s)
  end
end

return Duration
