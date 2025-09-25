local doc = require("mini.doc")
doc.setup({})
doc.generate({ "./lua/timers/types.lua" }, "./doc/timers.txt")
