all: install

.PHONY: install

install:
	mkdir -p ~/.config/nvim/lua/
	cp -R ./lua/code-evolve ~/.config/nvim/lua/

uninstall:
	rm -rf ~/.config/nvim/lua/code-evolve

format:
	lua-format -i --indent-width=2 ./lua/code-evolve/init.lua
	lua-format -i --indent-width=2 ./lua/code-evolve/parse-git-log.lua

