.PHONY: deps
deps:
	luarocks install busted

.PHONY: test
test:
	busted --lua=lua spec
