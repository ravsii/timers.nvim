local duration = require('timer.duration')
local timers = require('timer.timer')

local COMMANDS = {
  Start = 'TimerStart',
  Stop = 'TimerStop',
  CancelAll = 'TimerCancelAll',
}

local M = {
  -- Stores all active timers in a k-v pairs
  -- Keys are nvim's assigned timer IDs, so you can vim.fn.timer_stop() them
  ---@type table<integer, Timer>
  active_timers = {},
}

---@param opts Config
function M.setup(opts) M.setup_user_commands() end

--- Starts a timer and tracks it in Manager.active_timers
--- @param t Timer Timer object to start
--- @see Timer.cancel
function M.start_timer(t)
  local id = vim.fn.timer_start(t.duration:asMilliseconds(), function()
    vim.notify(t.message, vim.log.levels.INFO)
    if t.callback then
      t.callback()
    end
    M.active_timers[t.id] = nil
  end)

  t.id = id
  M.active_timers[t.id] = t
end

---@return Timer? timer First timer that's about to expire or nil, if there are
---no timers
function M.get_closest_timer()
  ---@type Timer?
  local minTimer = nil
  local minRemaining = math.huge -- start with infinity

  local now = os.time()

  for _, t in pairs(M.active_timers) do
    local expire_at = t.created + t.duration:asSeconds()
    local remaining = expire_at - now

    if remaining > 0 and remaining < minRemaining then
      minRemaining = remaining
      minTimer = t
    end
  end

  return minTimer
end

--- Cancel all active timers
function M.cancel_all()
  for _, t in pairs(M.active_timers) do
    t:cancel()
  end
  M.active_timers = {}
end

function M.setup_user_commands()
  vim.api.nvim_create_user_command(COMMANDS.Start, function(opts)
    local args = opts.args
    local i = args:find('%s')

    local duration_str, message
    if i then
      duration_str = args:sub(1, i - 1)
      message = args:sub(i + 1)
    else
      duration_str = args
    end

    local d = duration.parse_format(duration_str)
    local t = timers.new(d, message)
    M.start_timer(t)
  end, { nargs = '+' })

  vim.api.nvim_create_user_command(COMMANDS.CancelAll, function() M.cancel_all() end, { nargs = 0 })
end

return M
