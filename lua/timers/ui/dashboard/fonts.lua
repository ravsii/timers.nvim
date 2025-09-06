local fonts = {
  ["tmplr"] = {
    ["s"] = {
      " ",
      "┏",
      "┛",
    },
    [":"] = {
      " ",
      "•",
      "•",
    },
    ["1"] = {
      "┓",
      "┃",
      "┻",
    },
    ["2"] = {
      "┏┓",
      "┏┛",
      "┗━",
    },
    ["3"] = {
      "┏┓",
      " ┫",
      "┗┛",
    },
    ["4"] = {
      "┃┃",
      "┗╋",
      " ┃",
    },
    ["5"] = {
      "┏━",
      "┗┓",
      "┗┛",
    },
    ["6"] = {
      "┏┓",
      "┣┓",
      "┗┛",
    },
    ["7"] = {
      "━┓",
      " ┃",
      " ╹",
    },
    ["8"] = {
      "┏┓",
      "┣┫",
      "┗┛",
    },
    ["9"] = {
      "┏┓",
      "┗┫",
      "┗┛",
    },
    ["0"] = {
      "┏┓",
      "┃┫",
      "┗┛",
    },
  },
}

local F = {}

---@param dur Duration
---@param font? string
---@return string[]
function F.from_duration(dur, font)
  local chars = fonts[font] or fonts["tmplr"]

  local max_rows = 0
  for _, v in pairs(chars) do
    max_rows = math.max(max_rows, #v)
  end

  local lines = {}
  for i = 1, max_rows do
    lines[i] = ""
  end

  local s = dur:into_hms()
  for i = 1, #s do
    local ch = s:sub(i, i)
    local digit = chars[ch]
    for row = 1, max_rows do
      lines[row] = lines[row] .. (digit[row] or string.rep("?", #digit[0]))
      if i ~= #s then
        lines[row] = lines[row] .. " "
      end
    end
  end

  return lines
end

return F
