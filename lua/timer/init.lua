local config = require('timer.config')
local duration = require('timer.duration')
local timers = require('timer.timer')
local unit = require('timer.unit')

---@class FileTimerState
---@field message string
---@field created number  -- os.time()
---@field duration Duration

local state_file = vim.fn.stdpath('data') .. '/timer.nvim/state.json'

local COMMANDS = {
  Start = 'TimerStart',
  Stop = 'TimerStop',
  CancelAll = 'TimerCancelAll',
}

---@alias TimerTable table<integer, Timer>

local M = {
  -- Stores all active timers in a k-v pairs
  -- Keys are nvim's assigned timer IDs, so you can vim.fn.timer_stop() them
  ---@type TimerTable
  active_timers = {},

  ---@type Config
  opts = config.defaults,
}

---@param opts Config
function M.setup(opts)
  M.opts = vim.tbl_deep_extend('force', M.opts, opts or {})
  M.setup_user_commands()
  M.setup_autocmds()
  M.load_state()
end

---Starts a timer and tracks it in Manager.active_timers
---@see Timer.cancel
---@param t Timer Timer object to start
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
  M.save_state()
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

local aug = vim.api.nvim_create_augroup('TimerSaveState', { clear = true })
function M.setup_autocmds()
  vim.api.nvim_create_autocmd('VimLeavePre', {
    group = aug,
    callback = function() M.save_state() end,
  })
end

function M.save_state()
  if not M.opts.persistent or M.active_timers_num() == 0 then
    return
  end

  local dir = vim.fn.fnamemodify(state_file, ':h')
  vim.fn.mkdir(dir, 'p')

  ---@type FileTimerState[]
  local saved = {}

  for _, t in pairs(M.active_timers) do
    table.insert(
      saved, ---@type FileTimerState
      {
        created = t.created,
        message = t.message,
        duration = t.duration,
      }
    )
  end

  local data = vim.fn.json_encode(saved)
  vim.fn.writefile({ data }, state_file)
end

function M.load_state()
  if not M.opts.persistent then
    return
  end

  if vim.uv.fs_stat(state_file) == nil then
    return
  end

  ---@type FileTimerState[]
  local old_timers = vim.fn.json_decode(vim.fn.readfile(state_file))
  local cur_time = os.time()

  for _, t in ipairs(old_timers) do
    local sub = duration.from((cur_time - t.created) * unit.SECOND)
    local time_left = duration.from(t.duration.value):sub(sub)
    if time_left.value > 0 then
      M.start_timer(timers.new(time_left, t.message))
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
