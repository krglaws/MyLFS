#!/usr/bin/env bash
# Less Stage 6
# ~~~~~~~~~~~~
set -e

cd /sources

eval "$(grep LESS $PACKAGE_LIST)"
PKG_LESS=$(basename $PKG_LESS)

tar -xf $PKG_LESS
cd ${PKG_LESS%.tar*}

./configure --prefix=/usr --sysconfdir=/etc

make

make install

cd /sources
rm -rf ${PKG_LESS%.tar*}

