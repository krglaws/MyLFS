#!/usr/bin/env bash
# Bison Stage 5
# ~~~~~~~~~~~~~
set -e

cd /sources

eval "$(grep BISON $PACKAGE_LIST)"
PKG_BISON=$(basename $PKG_BISON)

tar -xf $PKG_BISON
cd ${PKG_BISON%.tar*}

./configure --prefix=/usr \
            --docdir=/usr/share/doc/${PKG_BISON%.tar*}

make
make install

cd /sources
rm -rf ${PKG_BISON%.tar*}

