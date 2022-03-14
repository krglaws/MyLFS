#!/usr/bin/env bash
# Make Stage 6
# ~~~~~~~~~~~~
set -e

cd /sources

eval "$(grep MAKE $PACKAGE_LIST)"
PKG_MAKE=$(basename $PKG_MAKE)

tar -xf $PKG_MAKE
cd ${PKG_MAKE%.tar*}

./configure --prefix=/usr

make

make check

make install

cd /sources
rm -rf ${PKG_MAKE%.tar*}

