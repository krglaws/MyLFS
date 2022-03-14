#!/usr/bin/env bash
# Groff Stage 6
# ~~~~~~~~~~~~~
set -e

cd /sources

eval "$(grep GROFF $PACKAGE_LIST)"
PKG_GROFF=$(basename $PKG_GROFF)

tar -xf $PKG_GROFF
cd ${PKG_GROFF%.tar*}

PAGE=letter ./configure --prefix=/usr

make -j1

make install

cd /sources
rm -rf ${PKG_GROFF%.tar*}

