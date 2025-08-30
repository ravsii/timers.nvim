--- This contains some keybinds to quickly test stuff

local d = require("timer.duration")
local m = require("timer")
local t = require("timer.timer")
local u = require("timer.unit")

local map = vim.keymap.set

map({ "n" }, "<leader>Tp", function()
  -- Duration as ms
  local break_duration = 5 * 60 * 1000

  local break_timer = t.new(break_duration, {
    message = "Break is over",
    title = "Break",
    log_level = 1,
    icon = "⏾",
    on_start = function() vim.notify("starting break timer") end,
  })

  -- or, using a go-like api
  local ppomodoro_duration = d.from(25 * u.MINUTE)

  local pomodoro_timer = t.new(ppomodoro_duration, {
    title = "Pomodoro",
    message = "Pomodoro is over",
    log_level = 4,
    icon = "",
    on_finish = function() m.start_timer(break_timer) end,
  })

  m.start_timer(pomodoro_timer)
end, { desc = "Timer Pomodoro Test" })
