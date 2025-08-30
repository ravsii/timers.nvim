local Duration = require("timer.duration")
local Unit = require("timer.unit")
local config = require("timer.config")

---@class Timer:TimerOpts
---@field created number  -- os.time()
---@field duration Duration
local Timer = {}
Timer.__index = Timer

---@class TimerOpts
---Message that shows up on timer finish.
---No effect, if on_start is passed.
---@field message? string
---Icon that will be passed to nvim.notify, false to don't pass anything
---@field icon? string | boolean
---@field title? string
---@field log_level? vim.log.levels
---Can be used to replace the default callback
---@field on_start? fun(t: Timer)
---Can be used to replace the default callback
---@field on_finish? fun(t: Timer)

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

  local timer = vim.tbl_extend("force", config.default_timer, opts, { ---@type Timer
    created = os.time(),
    duration = duration,
  })

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
