---@class Duration
---@field value integer Duration in milliseconds
local Duration = {}
Duration.__index = Duration

Duration.MILLISECOND = 1
Duration.SECOND = Duration.MILLISECOND * 1000
Duration.MINUTE = Duration.SECOND * 60
Duration.HOUR = Duration.MINUTE * 60

---Create a new Duration object
---@param ms? integer duration in milliseconds (default: 0)
---@return Duration
function Duration.new(ms) return setmetatable({ value = ms or 0 }, Duration) end

---Return value in milliseconds
---@return integer ms milliseconds, suitable for lua functions
function Duration:asMilliseconds() return self.value end

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
function Duration.parse(str)
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

  local function addUnit(unit)
    local total = curNum + (fracNum / fracDiv)
    result = result + total * unit
    -- reset state
    curNum, fracNum, fracDiv, inFraction = 0, 0, 1, false
  end

  local cases = {
    ['0'] = function() addNum(0) end,
    ['1'] = function() addNum(1) end,
    ['2'] = function() addNum(2) end,
    ['3'] = function() addNum(3) end,
    ['4'] = function() addNum(4) end,
    ['5'] = function() addNum(5) end,
    ['6'] = function() addNum(6) end,
    ['7'] = function() addNum(7) end,
    ['8'] = function() addNum(8) end,
    ['9'] = function() addNum(9) end,
    ['.'] = function() inFraction = true end,
    ['s'] = function() addUnit(self.SECOND) end,
    ['m'] = function() addUnit(self.MINUTE) end,
    ['h'] = function() addUnit(self.HOUR) end,
  }

  for c in str:gmatch('.') do
    (cases[c] or function() error('Unexpected char: ' .. c) end)()
  end

  self.value = result
  return self
end

return Duration
