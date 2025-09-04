local config = require("timer.config")
local duration = require("timer.duration")
local unit = require("timer.unit")

---@class TimerOpts
---Message that shows up on timer finish.
---No effect, if on_start is passed.
---@field message? string
---Icon that will be passed to nvim.notify, false to don't pass anything
---@field icon? string | boolean
---@field title? string
---@field log_level? vim.log.levels
---Can be used to replace the default callback
---@field on_start? fun(t: Timer, timer_id: integer)
---Can be used to replace the default callback
---@field on_finish? fun(t: Timer, timer_id: integer)

---@class Timer:TimerOpts
---@field started number  -- os.time() in seconds, when it was started.
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

  ---@type Timer
  local timer = vim.tbl_extend("force", config.default_timer, opts, { duration = dur })
  local self = setmetatable(timer, T)

  return self
end

---Returns remaining duration of a timer.
---@return Duration
function T:expire_in()
  local expire_at = self.started + self.duration:asSeconds()
  local remaining = expire_at - os.time()
  return duration.from(remaining * unit.SECOND)
end

return T
