# timer.nvim

`timer.nvim` is a simple timer management plugin for Neovim that allows you to
**run, track, and manage multiple timers**. Its core focus is **extensibility**
and providing a **clean API** for other plugins or custom configurations.

> [!WARNING]
>
> **This library is in active development!**

## Table Of Contents

<!--toc:start-->
- [timer.nvim](#timernvim)
  - [Table Of Contents](#table-of-contents)
  - [Installation](#installation)
  - [Commands](#commands)
    - [`:TimerStart` Usage](#timerstart-usage)
      - [Duration format](#duration-format)
      - [Examples](#examples)
  - [Integrations](#integrations)
    - [Lualine](#lualine)
      - [Closest timer](#closest-timer)
  - [API](#api)
    - [Recipes](#recipes)
      - [Pomodoro Timer with break](#pomodoro-timer-with-break)
<!--toc:end-->

## Installation

Using `lazy.nvim`:

```lua
{
  'ravsii/timer.nvim',
  ---@module "timer.config"
  ---@type Config
  opts = {
    -- Save timers across reloads / sessions.
    -- If true, neovim will save your active timers on disk and load them
    -- back after you enter it again.
    -- Keep in mind that timer is _still_ ticking, even when Neovim is
    -- closed.
    persistent = true,
  },
}
```

## Commands

`timer.nvim` provides the following Neovim user commands:

| Command           | Description                                 |
| ----------------- | ------------------------------------------- |
| `:TimerStart`     | Start a new timer. For more info see below. |
| `:TimerCancelAll` | Cancel all currently active timers.         |

### `:TimerStart` Usage

Starts a timer using a **duration string**, similar to Go’s `time.Duration`
format:

#### Duration format

- `s` → seconds
- `m` → minutes
- `h` → hours
- Numbers without a unit are treated as milliseconds

#### Examples

```vim
:TimerStart 3m Take a short break!      " 3 minutes
:TimerStart 3.5m Stretch now!           " 3 minutes 30 seconds
:TimerStart 1.75h Long task reminder    " 1 hour 45 minutes
:TimerStart 45s Quick notification      " 45 seconds
:TimerStart 1500 Quick ping             " 1500 milliseconds (1.5s)
:TimerStart 10                          " 10 milliseconds
:TimerStart 10h29m59s Complex Time      " 10 hours 29 minutes and 59 seconds
```

> Notes:
>
> - If no message is provided, the default message is `"Timer finished!"`.
> - The message can contain spaces; everything after the first space is treated
>   as the message.

## Integrations

### Lualine

#### Closest timer

You can display the closest timer to expire** in `lualine`:

![lualine integration](./pics/lualine.jpg)

```lua
{
  'nvim-lualine/lualine.nvim',
  opts = {
    sections = {
      -- other secions
      lualine_y = { { "location" } },
      lualine_z = {
        { require("timer.integrations.lualine").closest_timer },
        { 'progress' },
      },
    },
  },
}
```

## API

### Recipes

#### Pomodoro Timer with break

```lua
{
  "<leader>Tp",
  function()
    local t = require("timer.timer")
    local d = require("timer.duration")
    local u = require("timer.unit")
    local m = require("timer")

    local break_timer = t.new(d.from(5 * u.MINUTE), "Break is over")
    local pomodoro_timer = t.new(
      d.from(25 * u.MINUTE),
      "Pomodoro is over",
      function() m.start_timer(break_timer) end
    )

    m.start_timer(pomodoro_timer)
  end,
  desc = "Start Pomodoro 25/5 timer",
},
```
