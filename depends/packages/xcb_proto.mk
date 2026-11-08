package=xcb_proto
$(package)_version=1.14.1
$(package)_download_path=https://xorg.freedesktop.org/archive/individual/proto
$(package)_file_name=xcb-proto-$($(package)_version).tar.xz
$(package)_sha256_hash=f04add9a972ac334ea11d9d7eb4fc7f8883835da3e4859c9afa971efdf57fcc3

# The py-compile script in this old tarball does 'import imp', a module that
# was removed in Python 3.12. Provide the two functions it uses instead, so the
# build works the same on old and new Python.
define $(package)_preprocess_cmds
  sed -i 's/^import sys, os, py_compile, imp/import sys, os, py_compile, importlib.util as _iu; imp = type(sys)(str()); imp.get_tag = lambda: sys.implementation.cache_tag; imp.cache_from_source = lambda p, d=None: _iu.cache_from_source(p) if d is None else _iu.cache_from_source(p, optimization=(str() if d else 1))/' py-compile
endef

define $(package)_config_cmds
  $($(package)_autoconf)
endef

define $(package)_build_cmds
  $(MAKE)
endef

define $(package)_stage_cmds
  $(MAKE) DESTDIR=$($(package)_staging_dir) install
endef

define $(package)_postprocess_cmds
  rm -rf lib/python*/site-packages/xcbgen/__pycache__
endef
