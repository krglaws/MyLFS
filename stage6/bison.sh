#!/usr/bin/env bash
# Bison Stage 6
# ~~~~~~~~~~~~~
set -e

cd /sources

eval "$(grep BISON $PACKAGE_LIST)"
PKG_BISON=$(basename $PKG_BISON)

tar -xf $PKG_BISON
cd ${PKG_BISON%.tar*}

./configure --prefix=/usr --docdir=/usr/share/doc/bison-3.8.2

make

make check

make install

cd /sources
rm -rf ${PKG_BISON%.tar*}

