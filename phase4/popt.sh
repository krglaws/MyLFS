#!/usr/bin/env bash
# Popt Stage 6
# ~~~~~~~~~~~~
set -e

cd /sources

eval "$(grep POPT $PACKAGE_LIST)"
PKG_POPT=$(basename $PKG_POPT)

tar -xf $PKG_POPT
cd ${PKG_POPT%.tar*}

./configure --prefix=/usr --disable-static

make

make install

cd /sources
rm -rf ${PKG_POPT%.tar*}

