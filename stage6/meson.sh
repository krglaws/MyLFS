#!/usr/bin/env bash
# Meson Stage 6
# ~~~~~~~~~~~~~
set -e

cd /sources

eval "$(grep COREUTILS $PACKAGE_LIST)"
PKG_COREUTILS=$(basename $PKG_COREUTILS)

tar -xf $PKG_COREUTILS
cd ${PKG_COREUTILS%.tar*}

python3 setup.py build

python3 setup.py install --root=dest
cp -r dest/* /
install -Dm644 data/shell-completions/bash/meson /usr/share/bash-completion/completions/meson
install -Dm644 data/shell-completions/zsh/_meson /usr/share/zsh/site-functions/_meson

cd /sources
rm -rf ${PKG_COREUTILS%.tar*}

