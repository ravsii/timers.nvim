local U = {}

---Returns size and start coordinates.
---@param width integer Desired width. Absolute if > 1, percentage if <= 1
---@param height integer Desired height. Absolute if > 1, percentage if <= 1
---@return integer width
---@return integer height
---@return integer row
---@return integer col
function U.calc_popup_size(width, height)
  if width <= 1 then
    width = math.floor(vim.o.columns * width)
  end

  local statusline_height = vim.o.laststatus > 1 and 1 or 0

  -- Account for additional UI elements if present (e.g., Lualine)
  -- Lualine typically uses `laststatus`, so `statusline_height` often suffices.
  local main_height = vim.o.lines - vim.o.cmdheight - statusline_height

  if height <= 1 then
    height = math.floor(main_height * height)
  end

  local row = math.floor((main_height - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  return width, height, row, col
end

return U
