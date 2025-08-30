local Duration = require('timer.duration')
local Unit = require('timer.unit')

---@class Timer:TimerOpts
---@field created number  -- os.time()
---@field duration Duration
local Timer = {}
Timer.__index = Timer

---@class TimerOpts
---@field message? string -- message that shows up on timer finish. "Timer Finished!" is used if it's empty.
---@field icon? string | boolean -- icon that will be passed to nvim.notify, false to don't pass anything
---@field title? string
---@field on_start? fun() extra callback on timer start
---@field on_finish? fun() extra callback on timer finish

---Create a new timer.
---@see TimerManager.start_timer starts it.
---@param duration Duration
---@param opts? TimerOpts
---@return Timer
function Timer.new(duration, opts)
  opts = opts or {}

  local timer = vim.tbl_extend('keep', {
    duration = duration,
    created = os.time(),
    message = opts.message or 'Timer finished!',
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
