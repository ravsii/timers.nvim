local config = require("timers.config")
local duration = require("timers.duration")
local unit = require("timers.unit")

---Represents a time returned by os.time() in seconds.
---@alias time number

---@class TimerOpts
---Message that shows up on timer finish.
---No effect, if on_start is passed.
---@field message? string
---Icon that will be passed to nvim.notify, false to disable.
---@field icon? string | boolean
---@field title? string
---@field log_level? vim.log.levels
---Can be used to replace the default callback
---@field on_start? fun(t: Timer, timer_id: integer)
---Can be used to replace the default callback
---@field on_finish? fun(t: Timer, timer_id: integer)

---@class Timer:TimerOpts
---When the timer was created. "Created" here means when :new() was called, not
---when manager.start_timer() was called.
---@field created_at time
---When the timer was started, using manager.start_timer().
---@field started_at time?
---When the timer was paused. If it's not nil, then the timer is currently
---paused.
---@field paused_at time?
---@field duration Duration
local T = {}
T.__index = T

---Create a new timer.
---@see TimerManager.start_timer starts it.
---@param dur Duration|number If number, it's converted to Duration as ms.
---@param opts? TimerOpts
---@return Timer
function T.new(dur, opts)
  opts = opts or {}

  if type(dur) == "number" then
    dur = duration.from(dur)
  end

  assert(getmetatable(dur) == duration, "Timer.new: duration must be a number or Duration")

  local base_timer = { created_at = os.time(), duration = dur } ---@type Timer

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
