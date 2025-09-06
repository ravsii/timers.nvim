--- This contains some keybinds to quickly test stuff

local d = require("timers.duration")
local m = require("timers.manager")
local t = require("timers.timer")
local u = require("timers.unit")

local map = vim.keymap.set

map({ "n" }, "<leader>Ti", function()
  local infinite_timer
  infinite_timer = t.new(d.from(5 * u.SECOND), {
    title = "Infinite",
    message = "It never ends",
    icon = "♾️",
    on_finish = function() m.start_timer(infinite_timer) end,
  })

  m.start_timer(infinite_timer)
end, { desc = "Test Infinite Timer" })

map({ "n" }, "<leader>Tt", function()
  -- Duration as ms
  local break_duration = 5 * 1000 -- 5 seconds

  local break_timer = t.new(break_duration, {
    message = "Break is over",
    title = "Break",
    log_level = 1,
    icon = "⏾",
    on_start = function() vim.notify("starting break timer") end,
  })

  -- or, using a go-like api
  local ppomodoro_duration = d.from(5 * u.SECOND)

  local pomodoro_timer = t.new(ppomodoro_duration, {
    title = "Pomodoro",
    message = "Pomodoro is over",
    log_level = 4,
    icon = "",
    on_finish = function() m.start_timer(break_timer) end,
  })

  m.start_timer(pomodoro_timer)
end, { desc = "Test Pomodoro timer (fast)" })

map({ "n" }, "<leader>TP", function()
  local break_duration = 5 * u.MINUTE
  local break_timer = t.new(break_duration, {
    message = "Break is over",
    title = "Break",
    log_level = 1,
    icon = "⏾",
    on_start = function() vim.notify("starting break timer") end,
  })

  local ppomodoro_duration = d.from(25 * u.MINUTE)
  local pomodoro_timer = t.new(ppomodoro_duration, {
    title = "Pomodoro",
    message = "Pomodoro is over",
    log_level = 4,
    icon = "",
    on_finish = function() m.start_timer(break_timer) end,
  })

  m.start_timer(pomodoro_timer)
end, { desc = "Test Pomodoro timer" })

-- map({ "n" }, "<leader>Tt", function() m.start_timer(t.new(1000)) end, { desc = "Test Default Timer" })
map({ "n" }, "<leader>Tl", function() m.start_timer(t.new(d.from(u.HOUR))) end, { desc = "Test Long Timer" })
map({ "n" }, "<leader>Ta", function() require("timers.ui").active_timers() end, { desc = "Active timers" })
map({ "n" }, "<leader>Tf", function() require("timers.ui.dashboard").show() end, { desc = "Fullscreen" })
map({ "n" }, "<leader>Tc", function() require("timers.ui").cancel() end, { desc = "Cancel a timer" })
map({ "n" }, "<leader>TC", function() require("timers.ui").cancel_all() end, { desc = "Cancel all timers" })
