local config = require("timers.config")
local fonts_lib = require("timers.ui.dashboard_fonts_lib")

local F = {
  fonts = fonts_lib,
}

function F.setup()
  if config.dashboard == nil then
    return
  end

  F.fonts = vim.tbl_deep_extend("force", F.fonts, config.dashboard.fonts or {})
end

---@param dur Duration
---@param font_name? string
---@return string[]
function F.from_duration(dur, font_name)
  local font = F.fonts[font_name] or F.fonts["tmplr"]

  local max_rows = 0
  for k, v in pairs(font) do
    if k ~= "padding" then
      max_rows = math.max(max_rows, #v)
    end
  end

  local padding_str = string.rep(" ", (font.padding or 1))

  local lines = {}
  for i = 1, max_rows do
    lines[i] = ""
  end

  local s = dur:into_hms()
  for i = 1, #s do
    local char = s:sub(i, i)
    local digit = font[char]
    for row = 1, max_rows do
      ---@diagnostic disable-next-line: need-check-nil
      lines[row] = lines[row] .. (digit[row] or string.rep("?", #digit[0]))
      if i ~= #s then
        lines[row] = lines[row] .. padding_str
      end
    end
  end

  return lines
end

return F
