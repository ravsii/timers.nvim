local config = require("timers.config")
local debug = require("timers.debug")
local duration = require("timers.duration")
local timer = require("timers.timer")
local unit = require("timers.unit")

local state_file = vim.fn.stdpath("data") .. "/timers.nvim/timers.json"

---@alias TimerTable table<integer, Timer>

---@alias InternalTable table<integer, InternalTableItem>
---@alias InternalTableItem { timer: Timer, _uv: uv.uv_timer_t, }

---@class Manager
local M = _G.__TIMERS_MANAGER
if not M then
  M = {
    ---Stores all active timers in a k-v pairs.
    ---@private
    ---@type InternalTable
    active_timers = {},

    ---Provides IDs for timers, so that they can be easily identified. It's
    ---also a bit of a legacy code, since initially we were using vim.fn timers
    ---instead of vim.uv timers.
    ---@private
    next_id = 1,
  }
  _G.__TIMERS_MANAGER = M
end

_G.__TIMERS_MANAGER_LOADED = _G.__TIMERS_MANAGER_LOADED or false

function M.setup()
  -- fix duplicates on :Lazy reload timers.nvim
  if not _G.__TIMERS_MANAGER_LOADED then
    M.load_state()
    _G.__TIMERS_MANAGER_LOADED = true
  end
end

---Starts a timer and tracks it in TimerManager.active_timers. The function
---returns 2 values for cancellation.
---@param t Timer Timer object to start.
---@return integer id Timer ID
---@return fun() cancel Cancel func that can be used to stop the timer. It
---already knows the correct ID.
function M.start_timer(t)
  local id = M.next_id or 1
  M.next_id = id + 1

  local notify_opts = { title = t.title, icon = t.icon }
  local cancel_func = function()
    M.cancel(id)
  end

  local uv_timer, err, err_name = vim.uv.new_timer()
  if uv_timer == nil then
    vim.notify("Can't create timer (" .. err_name .. "):" .. err, vim.log.levels.ERROR, notify_opts)
    return -1, function() end
  end

  uv_timer:start(t.duration:asMilliseconds(), 0, function()
    cancel_func()
    if t.on_finish then
      t.on_finish(t, id)
    else
      vim.notify(t.message, t.log_level, notify_opts)
    end
  end)

  t.started_at = os.time()
  local table_item = { timer = t, _uv = uv_timer } ---@type InternalTableItem
  M.active_timers[id] = table_item
  M.save_state()

  debug.log("new timer added " .. vim.inspect(t))
  debug.log("state after creation " .. vim.inspect(M.active_timers))

  if t.on_start then
    t.on_start(t, id)
  else
    local start_msg = "Timer for " .. t.duration:into_hms() .. " started"
    vim.notify(start_msg, t.log_level, notify_opts)
  end

  return id, cancel_func
end

---@return Timer? timer First timer that's about to expire or nil, if there are
---no timers.
function M.get_closest_timer()
  ---@type Timer?
  local minTimer = nil
  local minRemaining = math.huge -- start with infinity

  local now = os.time()

  for _, t in pairs(M.timers()) do
    local expire_at = t.started_at + t.duration:asSeconds()
    local remaining = expire_at - now

    if remaining < minRemaining then
      minRemaining = remaining
      minTimer = t
    end
  end

  return minTimer
end

---Returns all active timers.
---@return TimerTable
function M.timers()
  local result = {} ---@type TimerTable

  for id, t in pairs(M.active_timers) do
    result[id] = t.timer
  end

  return result
end

---@return integer count Amount of active timers
function M.active_timers_num()
  local count = 0
  for _ in pairs(M.active_timers) do
    count = count + 1
  end
  return count
end

---Resume a timer by id, if it was paused.
---This works as starting a new timers from scratch, so started_at and
---paused_at properties will be reset.
---@param id integer
---@return boolean resumed true if the timer exists, was paused and resumed.
function M.resume(id)
  local t = M.active_timers[id]
  if t == nil then
    return false
  end

  -- TODO: this

  return true
end

---Pause a timer by id
---@param id integer
---@return boolean paused true if the timer was found and paused.
function M.pause(id)
  local t = M.active_timers[id]
  if t == nil then
    return false
  end

  t._uv:stop()
  t.timer.paused_at = os.time()

  return true
end

---Cancel a timer by id
---@param id integer
---@return boolean canceled true if the timer was found and stopped
function M.cancel(id)
  local t = M.active_timers[id]
  if t == nil then
    return false
  end

  t._uv:stop()
  t._uv:close()

  M.active_timers[id] = nil
  M.save_state()

  return true
end

---Cancel and drop all active timers
function M.cancel_all()
  for id, t in pairs(M.active_timers) do
    t._uv:stop()
    t._uv:close()
    M.active_timers[id] = nil
  end
  M.save_state()
end

---@private
function M.save_state()
  if not config.persistent then
    return
  end

  local dir = vim.fn.fnamemodify(state_file, ":h")
  vim.fn.mkdir(dir, "p")

  ---@type Timer[]
  local saved = {}

  for _, t in pairs(M.timers()) do
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
    -- Timer was running up until now, or, if it was paused, until paused_at
    local ran_until = opts.paused_at and opts.paused_at or cur_time

    local time_left =
      duration.from(opts.duration.value):sub((ran_until - opts.started_at) * unit.SECOND)

    if opts.duration.value > 0 then
      local tid = M.start_timer(timer.new(time_left, opts))
      -- It's easier to handle paused timers this way, instead of recreating
      -- the entire start_timer from scratch.
      -- At least for now.
      if opts.paused_at then
        M.pause(tid)
      end
    end
  end
end

return M
