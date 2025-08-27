# timer.nvim

`timer.nvim` is a simple timer management plugin for Neovim that allows you to
**run, track, and manage multiple timers**. Its core focus is **extensibility**
and providing a **clean API** for other plugins or custom configurations.

## Installation

Using `lazy.nvim`:

```lua
return {
  {
    'ravsii/timer.nvim',
    opts = {}, -- no options for now
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

* `s` → seconds
* `m` → minutes
* `h` → hours
* Numbers without a unit are treated as milliseconds

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
> * If no message is provided, the default message is `"Timer finished!"`.
> * The message can contain spaces; everything after the first space is treated
>   as the message.

## Integrations

### Lualine

#### Closest timer

You can display the closest timer to expire in `lualine`:

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

## TODO

* [ ] Saving timers across sessions, so that quitting Neovim (`:wqa`) does not
lose active timers.
