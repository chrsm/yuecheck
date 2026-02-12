package = 'yuecheck'
version = 'dev-1'

source = {
  url = 'git+ssh://git@github.com/chrsm/yuecheck.git'
}

description = {
  summary = 'Yue utility lib and tooling',
  detailed = '',
  homepage = 'https://github.com/chrsm/yuecheck',
  license = 'MIT'
}

dependencies = {
  'lua >= 5.4',
  'YueScript >= 0.29.2',
  'lpeg >= 1.1.0-2',
  'lpegrex >= 0.2.2-1',
  'argparse >= 0.7.1',
  'inspect >= 3.1.3',
  'dkjson >= 2.8-2',
  'http >= 0.4-0',
  'busted >= 2.3.0-1',
}

build = {
  type = 'make',
  build_target = 'build',
  build_variables = {
    LUA        = '$(LUA)',
    LUA_BINDIR = '$(BINDIR)',
    LUA_DIR    = '$(LUADIR)',
    LUA_INCDIR = '$(LUA_INCDIR)',
    LUA_LIBDIR = '$(LIBDIR)',
  },
  install_variables = {
    INST_PREFIX  = '$(PREFIX)',
    INST_BINDIR  = '$(BINDIR)',
    INST_LIBDIR  = '$(LIBDIR)',
    INST_LUADIR  = '$(LUADIR)',
    INST_CONFDIR = '$(CONFDIR)',
  },
}
