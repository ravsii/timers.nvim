local Duration = require("timer.duration")
local Unit = require("timer.unit")

---@class Timer:TimerOpts
---@field created number  -- os.time()
---@field duration Duration
local Timer = {}
Timer.__index = Timer

---@class TimerOpts
---Message that shows up on timer finish.
---Defaults to "Timer Finished!", if not passed.
---No effect, if on_start is passed.
---@field message? string
---@field icon? string | boolean -- Icon that will be passed to nvim.notify, false to don't pass anything
---@field title? string
---@field log_level? vim.log.levels
---@field on_start? fun(Timer) Can be used to replace the default callback
---@field on_finish? fun(Timer) Can be used to replace the default callback

---Create a new timer.
---@see TimerManager.start_timer starts it.
---@param duration Duration|number If number, it's converted to Duration as ms.
---@param opts? TimerOpts
---@return Timer
function Timer.new(duration, opts)
  opts = opts or {}

  if type(duration) == "number" then
    duration = Duration.from(duration)
  end

  assert(getmetatable(duration) == Duration, "Timer.new: duration must be a number or Duration")

  local timer = vim.tbl_extend("keep", { ---@type Timer
    created = os.time(),
    duration = duration,
    log_level = vim.log.levels.INFO,
    message = opts.message or "Timer finished!",
  }, opts)

  local self = setmetatable(timer, Timer)

  return self
end

---Get remaining time in seconds
---@return Duration
function Timer:remaining()
  local expire_at = self.created + self.duration:asSeconds()
  local remaining = expire_at - os.time()
  return Duration.from(remaining * Unit.SECOND)
end

return Timer
