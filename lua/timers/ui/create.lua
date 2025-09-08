local config = require("timers.config")

local F = {
  namespace = vim.api.nvim_create_namespace("timers.nvim/create"),
}

---@alias fields field[]
---@alias field {title: string, placeholder: string}

---@type fields
local fields = {
  { title = "Title", placeholder = config.default_timer.title },
  { title = "Message", placeholder = config.default_timer.message },
  { title = "Duration", placeholder = "Examples: 1500, 3s, 2.5m, 1h2m3s" },
}

local binds = {
  { "<Tab>", "next" },
  { "<Enter>", "create" },
  { "q", "quit" },
}

function F:create_timer()
  local buf = vim.api.nvim_create_buf(false, true)
  local width = 40
  local height = 10

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = (vim.o.lines - height) / 2,
    col = (vim.o.columns - width) / 2,
    style = "minimal",
    border = "rounded",
    title = " User Form ",
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

  local buf_lines = {}
  for _ = 1, #fields + 1 do
    vim.list_extend(buf_lines, { "" })
  end

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, buf_lines)

  for i, field in pairs(fields) do
    vim.api.nvim_buf_set_extmark(buf, F.namespace, i - 1, 0, {
      virt_lines = {
        { { field.title, "Title" } },
      },
      virt_lines_above = true,

      virt_text = { { field.placeholder, "Comment" } },
      virt_text_pos = "eol",
    })
  end

  -- Only these lines are editable
  local fields = { 1, 2, 3 }
  local current_field = 1

  local function focus_field(i)
    vim.api.nvim_win_set_cursor(win, { i, 0 })
    vim.cmd("normal! zb")
  end

  -- Restrict cursor movement to allowed lines
  vim.api.nvim_create_autocmd("CursorMovedI", {
    buffer = buf,
    callback = function()
      local pos = vim.api.nvim_win_get_cursor(win)
      local lnum = fields[current_field]
      if pos[1] ~= lnum then
        vim.api.nvim_win_set_cursor(win, { lnum, pos[2] })
      end
    end,
  })

  -- Tab navigation
  vim.keymap.set("i", "<Tab>", function()
    current_field = (current_field % #fields) + 1
    focus_field(current_field)
  end, { buffer = buf })

  vim.keymap.set("i", "<S-Tab>", function()
    current_field = ((current_field - 2) % #fields) + 1
    focus_field(current_field)
  end, { buffer = buf })

  -- Submit
  vim.keymap.set("i", "<CR>", function()
    local results = {}
    for _, lnum in ipairs(fields) do
      local line = vim.api.nvim_buf_get_lines(buf, lnum - 1, lnum, false)[1]
      results[#results + 1] = line
    end
    vim.api.nvim_win_close(win, true)
    print("Submitted:", results[1], results[2])
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
