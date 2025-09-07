local config = require("timers.config")
local M = {}

---@alias fields field[]
---@alias field {title: string, placeholder: string}

---@type fields
local fields = {
  { title = "Title", placeholder = config.default_timer.title },
  { title = "Message", placeholder = config.default_timer.message },
  { title = "Duration", placeholder = "Examples: 1500, 3s, 2.5m, 1h2m3s" },
}

function M.open_form()
  local buf = vim.api.nvim_create_buf(false, true)
  local width = 40
  local height = 7
  local opts = {
    relative = "editor",
    width = width,
    height = height,
    row = (vim.o.lines - height) / 2,
    col = (vim.o.columns - width) / 2,
    style = "minimal",
    border = "rounded",
    title = " User Form ",
    title_pos = "center",
  }
  local win = vim.api.nvim_open_win(buf, true, opts)

  -- Buffer setup
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].modifiable = true

  -- Lines: labels + values
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
    "name1", -- label
    "v1", -- input line
    "name2", -- label
    "v2", -- input line
    "",
    "[Press Enter to submit | Esc to cancel]",
  })

  -- Highlight group for labels
  vim.api.nvim_set_hl(0, "FormLabel", { fg = "#FFD700", bold = true })

  -- Overlays for labels
  local ns = vim.api.nvim_create_namespace("form")
  vim.api.nvim_buf_set_extmark(buf, ns, 0, 0, {
    virt_text = { { "Name1", "Comment" } },
    virt_text_pos = "overlay",
  })
  vim.api.nvim_buf_set_extmark(buf, ns, 2, 0, {
    virt_text = { { "Name2", "Comment" } },
    virt_text_pos = "overlay",
  })

  -- Only these lines are editable
  local fields = { 2, 4 }
  local current_field = 1

  local function focus_field(i)
    vim.api.nvim_win_set_cursor(win, { fields[i], 0 })
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
  vim.keymap.set({ "i", "n" }, "<Esc>", function()
    vim.api.nvim_win_close(win, true)
  end, { buffer = buf })

  -- Start editing
  focus_field(current_field)
  vim.cmd("startinsert")
end

return M
