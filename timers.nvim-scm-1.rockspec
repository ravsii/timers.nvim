rockspec_format = "3.0"
package = "timers.nvim"
version = "scm-1"

test_dependencies = {
  "lua >= 5.1",
  "nlua",
  "busted",
  "luacov",
}

source = {
  url = "git://github.com/ravsii/" .. package,
}

build = {
  type = "builtin",
}
