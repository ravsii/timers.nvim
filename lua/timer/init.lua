local Duration = require('timer.duration')
local timers = require('timer.timers')

local M = {}

---@param opts Config
function M.setup(opts) M.setup_user_commands() end

function M.setup_user_commands()
  vim.api.nvim_create_user_command('StartTimer', function(opts)
    local args = opts.args
    local i = args:find('%s')

    local duration_str, message
    if i then
      duration_str = args:sub(1, i - 1)
      message = args:sub(i + 1)
    else
      duration_str = args
    end

    local duration = Duration.parse(duration_str)
    timers.start_timer(duration, message)
  end, { nargs = '+' })
end

return M
