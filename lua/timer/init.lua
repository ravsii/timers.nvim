local config = require("timer.config")
local duration = require("timer.duration")
local timer = require("timer.timer")
local unit = require("timer.unit")

local state_file = vim.fn.stdpath("data") .. "/timer.nvim/timers.json"

---@alias TimerTable table<integer, Timer>

---@class TimerManager
local M = {
  ---@type TimerTable
  ---Stores all active timers in a k-v pairs.
  ---Keys are nvim's assigned timer IDs, so you can vim.fn.timer_stop() them.
  ---WARN: Please, do not modify it. Use approprioate timer functions instead.
  active_timers = {},
}

---@param opts Config
function M.setup(opts)
  config.setup(opts or {})
  require("timer.commands").setup()
  require("timer.autocmd").setup()
  M.load_state()
end

---Starts a timer and tracks it in TimerManager.active_timers. The function
---returns 2 values for cancellation.
---@param t Timer Timer object to start.
---@return integer id Timer ID
---@return fun() cancel Cancel func that can be used to stop the timer. It
---already knows the correct ID.
function M.start_timer(t)
  ---ID is created here, but assigned later. It's required for callbacks so we
  ---have to do it this way.
  ---@type integer
  local id

  local notify_opts = { title = t.title, icon = t.icon }
  local cancel_func = function() M.cancel(id) end

  id = vim.fn.timer_start(t.duration:asMilliseconds(), function()
    cancel_func()
    if t.on_finish then
      t.on_finish(t)
    else
      vim.notify(t.message, t.log_level, notify_opts)
    end
  end)

  M.active_timers[id] = t
  M.save_state()

  if t.on_start then
    t.on_start(t)
  else
    local start_msg = "Timer for " .. t.duration:into_hms() .. " started"
    vim.notify(start_msg, t.log_level, notify_opts)
  end

  return id, cancel_func
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

---Cancels a timer by its id
---@param id integer
---@return boolean value true if the timer was found and stopped
function M.cancel(id)
  if M.active_timers[id] == nil then
    return false
  end

  vim.fn.timer_stop(id)
  M.active_timers[id] = nil
  M.save_state()

  return true
end

--- Cancel all active timers
function M.cancel_all()
  for id, _ in pairs(M.active_timers) do
    vim.fn.timer_stop(id)
  end
  M.active_timers = {}
  M.save_state()
end

function M.save_state()
  if not config.persistent then
    return
  end

  local dir = vim.fn.fnamemodify(state_file, ":h")
  vim.fn.mkdir(dir, "p")

  ---@type Timer[]
  local saved = {}

  for _, t in pairs(M.active_timers) do
    local copy = vim.tbl_deep_extend("force", {}, t)
    copy.on_start = nil
    copy.on_finish = nil
    table.insert(saved, copy)
  end

  local data = vim.fn.json_encode(saved)
  vim.fn.writefile({ data }, state_file)
end

function M.load_state()
  if not config.persistent then
    return
  end

  if vim.uv.fs_stat(state_file) == nil then
    return
  end

  ---@type Timer[]
  local old_timers = vim.fn.json_decode(vim.fn.readfile(state_file))
  local cur_time = os.time()

  for _, opts in ipairs(old_timers) do
    local sub = duration.from((cur_time - opts.created) * unit.SECOND)
    local time_left = duration.from(opts.duration.value):sub(sub)
    if time_left.value > 0 then
      M.start_timer(timer.new(time_left, opts))
    end
  end
end

---@return integer count Amount of active timers
function M.active_timers_num()
  local count = 0
  for _ in pairs(M.active_timers) do
    count = count + 1
  end
  return count
end

return M
