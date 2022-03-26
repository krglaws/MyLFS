#!/usr/bin/env bash
# Meson Stage 6
# ~~~~~~~~~~~~~
set -e

cd /sources

eval "$(grep MESON $PACKAGE_LIST)"
PKG_MESON=$(basename $PKG_MESON)

tar -xf $PKG_MESON
cd ${PKG_MESON%.tar*}

python3 setup.py build

python3 setup.py install --root=dest
cp -r dest/* /
install -Dm644 data/shell-completions/bash/meson /usr/share/bash-completion/completions/meson
install -Dm644 data/shell-completions/zsh/_meson /usr/share/zsh/site-functions/_meson

cd /sources
rm -rf ${PKG_MESON%.tar*}

