local config = require("timers.config")
local duration = require("timers.duration")
local manager = require("timers.manager")
local timer = require("timers.timer")

local notify_opts = { icon = "󱎫", title = "timers.nvim" }

local F = {
  namespace = vim.api.nvim_create_namespace("timers.nvim/create"),
}

---@alias fields field[]
---@alias field {
---   title: string,
---   required:boolean?,
---   placeholder: string,
---   line: integer?,
--- }

---@type fields
local base_fields = {
  { title = "󱎫 Duration", required = true, placeholder = "1500, 3s, 2.5m, 1h2m3s" },
  { title = "󰗴 Title", placeholder = config.default_timer.title },
  { title = " Message", placeholder = config.default_timer.message },
}

local binds = {
  { "<Tab>", "next" },
  { "<Enter>", "create" },
  { "q", "quit" },
}

function F:create_timer()
  local buf = vim.api.nvim_create_buf(false, true)
  local width = 40
  local height = #base_fields * 2 + 2

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = (vim.o.lines - height) / 2,
    col = (vim.o.columns - width) / 2,
    style = "minimal",
    border = "rounded",
    title = " New Timer ",
    title_pos = "center",
    footer = F:make_footer(),
    footer_pos = "right",
  })

  -- Buffer setup
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].modifiable = true
  vim.wo[win].scrolloff = 1
  vim.wo[win].wrap = true

  -- extra empty line so virt_lines_above could work normally.
  local buf_lines = { "" }
  for _ = 1, #base_fields do
    vim.list_extend(buf_lines, { "" })
  end

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, buf_lines)

  -- Only these lines are editable
  local fields = vim.tbl_deep_extend("force", {}, base_fields) ---@type fields
  for i in ipairs(fields) do
    fields[i].line = i
  end
  local current_field = 1

  local function draw()
    vim.api.nvim_buf_clear_namespace(buf, self.namespace, 0, -1)

    for i, field in pairs(base_fields) do
      local opts = { ---@type vim.api.keyset.set_extmark
        virt_lines = {
          {
            { field.title, "Title" },
            { field.required and " required" or "", "Conditional" },
          },
        },
        virt_lines_above = true,
      }

      local line_text = vim.api.nvim_buf_get_lines(buf, i, i + 1, false)[1] or ""

      if line_text == "" then
        opts = vim.tbl_deep_extend("keep", opts, {
          virt_text = { { field.placeholder, "Comment" } },
          virt_text_pos = "inline",
        })
      end

      vim.api.nvim_buf_set_extmark(buf, self.namespace, i, 0, opts)
    end
  end
  draw()

  local function focus_field(i)
    vim.api.nvim_win_set_cursor(win, { i + 1, 0 })
  end

  vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
    buffer = buf,
    callback = function()
      local pos = vim.api.nvim_win_get_cursor(win)
      local lnum = fields[current_field].line

      if pos[1] + 1 ~= lnum then
        local new_pos = vim.api.nvim_win_set_cursor(win, { lnum + 1, pos[2] })
      end
    end,
  })

  vim.api.nvim_create_autocmd("InsertEnter", {
    buffer = buf,
    callback = function()
      local pos = vim.api.nvim_win_get_cursor(win)
      current_field = pos[1] - 1
    end,
  })

  vim.api.nvim_create_autocmd({ "TextChangedI", "TextChanged" }, {
    buffer = buf,
    callback = function()
      if vim.api.nvim_buf_line_count(buf) < #fields + 1 then
        vim.api.nvim_buf_set_lines(buf, -1, -1, false, { "" })
      end

      draw()
    end,
  })

  -- Tab navigation
  vim.keymap.set({ "n", "i" }, "<Tab>", function()
    current_field = (current_field % #fields) + 1
    focus_field(current_field)
  end, { buffer = buf })

  vim.keymap.set({ "n", "i" }, "<S-Tab>", function()
    current_field = ((current_field - 2) % #fields) + 1
    focus_field(current_field)
  end, { buffer = buf })

  -- Submit
  vim.keymap.set({ "n", "i" }, "<CR>", function()
    local line = vim.api.nvim_buf_get_lines(buf, 1, -1, false)
    local duration_str = line[1]

    if duration_str == "" then
      vim.notify("Duration can't be empty", vim.log.levels.ERROR, notify_opts)
      return
    end

    local d = duration.parse_format(duration_str)

    local timer_opts = {} ---@type TimerOpts
    local title = line[2] or ""
    if title ~= "" then
      timer_opts.title = title
    end

    local message = line[3] or ""
    if message ~= "" then
      timer_opts.message = title
    end

    manager.start_timer(timer.new(d, timer_opts))

    vim.api.nvim_win_close(win, true)
  end, { buffer = buf })

  -- Cancel
  vim.keymap.set({ "n" }, "q", function()
    vim.api.nvim_win_close(win, true)
  end, { buffer = buf })

  -- Start editing
  focus_field(current_field)
  vim.cmd("startinsert")
end

---@private
function F.make_footer()
  local footer = {}

  for i, bind in pairs(binds) do
    if i > 1 then
      table.insert(footer, { " - ", "FloatBorder" })
    end

    vim.list_extend(footer, {
      { bind[1], "Character" },
      { " " .. bind[2], "Normal" },
    })
  end

  return footer
end

return F
