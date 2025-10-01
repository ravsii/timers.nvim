LUA_VERSION = 5.1
LUAROCKS_TREE = lua_modules

PATH := $(PWD)/$(LUAROCKS_TREE)/bin:$(PATH)
LUA_PATH := $(PWD)/$(LUAROCKS_TREE)/share/lua/$(LUA_VERSION)/?.lua;$(PWD)/$(LUAROCKS_TREE)/share/lua/$(LUA_VERSION)/?/init.lua;;
LUA_CPATH := $(PWD)/$(LUAROCKS_TREE)/lib/lua/$(LUA_VERSION)/?.so;;

.PHONY: deps test

deps:
	luarocks --lua-version=$(LUA_VERSION) --tree=$(LUAROCKS_TREE) install busted
	luarocks --lua-version=$(LUA_VERSION) --tree=$(LUAROCKS_TREE) install nvim-nlua
	luarocks --lua-version=$(LUA_VERSION) --tree=$(LUAROCKS_TREE) install --only-deps ./timers.nvim-scm-1.rockspec

test:
	luarocks --lua-version=$(LUA_VERSION) --tree=$(LUAROCKS_TREE) test --local
