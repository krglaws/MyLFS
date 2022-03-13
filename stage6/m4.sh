#!/usr/bin/env bash
# M4 Stage 6
# ~~~~~~~~~~
set -e

cd /sources

eval "$(grep M4 $PACKAGE_LIST)"
PKG_M4=$(basename $PKG_M4)

tar -xf $PKG_M4
cd ${PKG_M4%.tar*}

./configure --prefix=/usr

make
make check
make install

cd /sources
rm -rf ${PKG_M4%.tar*}

