.DEFAULT_GOAL := help

LUA_DIR=/usr
LUA_LIBDIR=$(LUA_DIR)/lib/lua/5.4
LUA_BINDIR=$(LUA_DIR)/bin
LUA=$(LUA_BINDIR)/lua5.4
LUA_INCDIR=$(LUA_DIR)/include
LUA_SHAREDIR=$(LUA_DIR)/share/lua/5.4

INST_PREFIX=/usr/local
INST_LIBDIR=$(INST_PREFIX)/lib/lua/5.4
INST_BINDIR=$(INST_PREFIX)/bin
INST_LUADIR=$(INST_PREFIX)/share/lua/5.4
INST_CONFDIR=$(INST_PREFIX)/etc

# <hack>
define nl


endef
define lrtestpath
./?.lua
./?/init.lua
$(HOME)/.luarocks/share/lua/5.4/?.lua
$(HOME)/.luarocks/share/lua/5.4/?/init.lua
/usr/share/lua/5.4/?.lua
/usr/share/lua/5.4/?/init.lua
endef
# </hack>
YCT_LPATH=$(subst $(nl),;,${lrtestpath})

.PHONY: all
all: generate test

.PHONY: build
## luarocks only
build: generate

.PHONY: install
## luarocks only
install:
	mkdir -p $(INST_LUADIR)/yuecheck
	cp -R src/yuecheck $(INST_LUADIR)/
	cp bin/yuecheck $(INST_BINDIR)/
	cp bin/yue-lsp $(INST_BINDIR)/
	cp bin/yuefmt $(INST_BINDIR)/

.PHONY: generate
## generate code from yue typedefs
generate:
	mkdir -p gen
	yue -e bin/fetch_ast.yue > gen/types_raw.yue
	yue -e bin/generate_types.yue > src/yuecheck/types.yue

.PHONY: test
## run all tests
test:
	export LUA_PATH='$(YCT_LPATH)' && cd src && \
		yue -e ../spec/rules.yue -v -C . -o gtest --exclude-tags='ignore' && \
		yue -e ../spec/lsp.yue -v -C . -o gtest --exclude-tags='ignore' && \
		yue -e ../spec/formatter.yue -v -C . -o gtest --exclude-tags='ignore'

# .PHONY: fmt
# fmt:
#	export LUA_PATH='$(YCT_LPATH)' && cd src && \
#		yue -e yuecheck/formatter.yue

.PHONY: lint
## run linter against itself
lint:
	export LUA_PATH='$(YCT_LPATH)' && cd src && \
		../bin/yuecheck .

temp:
	echo -e '$(LOCAL_TESTS)'

.PHONY: uninstall
## delete all installed files
uninstall:
	luarocks remove yuecheck
	rm -rf $(HOME)/.luarocks/bin/yuecheck
	rm -rf $(HOME)/.luarocks/bin/yue-lsp
	rm -rf $(HOME)/.luarocks/bin/yuefmt
	rm -rf $(HOME)/.luarocks/lib/luarocks/rocks-5.4/yuecheck
	rm -rf $(HOME)/.luarocks/share/lua/5.4/yuecheck

.PHONY: rock
## build and install rock locally
rock:
	luarocks --local --verbose make

.PHONY: help
## list available commands
help: Makefile
	# original source? https://gist.github.com/prwhite/8168133
	@echo "$$(tput bold)Available commands:$$(tput sgr0)";echo;sed -ne"/^## /{h;s/.*//;:d" -e"H;n;s/^## //;td" -e"s/:.*//;G;s/\\n## /---/;s/\\n/ /g;p;}" ${MAKEFILE_LIST}|awk -F --- -v n=$$(tput cols) -v i=19 -v a="$$(tput setaf 6)" -v z="$$(tput sgr0)" '{printf"%s%*s%s ",a,-i,$$1,z;m=split($$2,w," ");l=n-i;for(j=1;j<=m;j++){l-=length(w[j])+1;if(l<= 0){l=n-i-length(w[j])-1;printf"\n%*s ",-i," ";}printf"%s ",w[j];}printf"\n";}'|more $(shell test $(shell uname) == Darwin && echo '-Xr')
