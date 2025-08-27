local Duration = require('timer.duration')
local Unit = require('timer.unit')

---@class Timer
---@field id integer
---@field message string
---@field created number  -- os.time()
---@field duration Duration
---@field callback fun()?
local Timer = {}
Timer.__index = Timer

---Create a new timer instance. After being created, timer is not started and
---also not given an id. Check timer.manager.start_timer
---@param duration Duration
---@param message? string -- If message is nil, "Timer Finished!" will be used.
---@param callback? fun()
---@return Timer
function Timer.new(duration, message, callback)
  message = (message and message ~= '') and message or 'Timer finished!'

  local self = setmetatable({
    id = -1,
    message = message,
    created = os.time(),
    duration = duration,
    callback = callback,
  }, Timer)

  return self
end

function Timer:cancel()
  if self.id == -1 then
    return
  end
  vim.fn.timer_stop(self.id)
end

---Get remaining time in seconds
---@return Duration
function Timer:remaining()
  local expire_at = self.created + self.duration:asSeconds()
  local remaining = expire_at - os.time()
  return Duration.from(remaining * Unit.SECOND)
end

return Timer
