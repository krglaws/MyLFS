#!/usr/bin/env bash
# Patch Stage 6
# ~~~~~~~~~~~~~
set -e

cd /sources

eval "$(grep PATCH $PACKAGE_LIST)"
PKG_PATCH=$(basename $PKG_PATCH)

tar -xf $PKG_PATCH
cd ${PKG_PATCH%.tar*}

./configure --prefix=/usr

make

make check

make install

cd /sources
rm -rf ${PKG_PATCH%.tar*}

