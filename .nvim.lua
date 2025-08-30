--- This contains some keybinds to quickly test stuff

local map = vim.keymap.set

map({ "n" }, "<leader>Tp", function()
  local t = require("timer.timer")
  local d = require("timer.duration")
  local u = require("timer.unit")
  local m = require("timer")

  local break_timer = t.new(d.from(5 * u.MINUTE), {
    message = "Break is over",
    title = "Break",
    icon = "⏾",
    on_start = function() vim.notify("starting break timer") end,
  })

  local pomodoro_timer = t.new(d.from(25 * u.MINUTE), {
    title = "Pomodoro",
    message = "Pomodoro is over",
    icon = "",
    on_finish = function() m.start_timer(break_timer) end,
  })

  m.start_timer(pomodoro_timer)
end, { desc = "Timer Pomodoro Test" })
