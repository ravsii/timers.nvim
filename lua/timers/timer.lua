local config = require("timers.config")
local duration = require("timers.duration")
local unit = require("timers.unit")

---@class Timer
local T = {}
T.__index = T

---Create a new timer, but doesn't start it.
---@see TimerManager.start_timer
---@param dur Duration|number If number, it's converted to Duration as ms.
---@param opts? TimerOpts
---@return Timer
function T.new(dur, opts)
  opts = opts or {}

  if type(dur) == "number" then
    dur = duration.from(dur)
  end

  assert(getmetatable(dur) == duration, "Timer.new: duration must be a number or Duration")

  ---@type Timer
  local base_timer = {
    created_at = os.time(),
    duration = dur,
    paused_at = nil,
    started_at = nil,
  }

  ---@type Timer
  local timer = vim.tbl_extend("force", config.default_timer, opts, base_timer)
  local self = setmetatable(timer, T)

  return self
end

---Returns true if the timer is currently paused (but still active)
---@return boolean paused
function T:paused()
  return self.paused_at ~= nil
end

---Returns remaining duration of a timer.
---@return Duration
function T:expire_in()
  local expire_sec ---@type time
  if self.paused_at == nil then
    expire_sec = (self.started_at + self.duration:asSeconds()) - os.time()
  else
    expire_sec = self.duration:asSeconds() - (self.paused_at - self.started_at)
  end

  return duration.from(expire_sec * unit.SECOND)
end

return T
