--- This contains some keybinds to quickly test stuff

local d = require("timer.duration")
local m = require("timer")
local t = require("timer.timer")
local u = require("timer.unit")

local map = vim.keymap.set

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
map({ "n" }, "<leader>Ta", require("timer.ui").active_timers, { desc = "Active timers" })
map({ "n" }, "<leader>Tf", require("timer.ui.dashboard").show, { desc = "Fullscreen" })
map({ "n" }, "<leader>Tc", require("timer.ui").cancel, { desc = "Cancel a timer" })
map({ "n" }, "<leader>TC", require("timer.ui").cancel_all, { desc = "Cancel all timers" })
