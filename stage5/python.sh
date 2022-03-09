#!/usr/bin/env bash
# Python Stage 5
# ~~~~~~~~~~~~~~
set -e

cd /sources

eval "$(grep PYTHON $PACKAGE_LIST)"
PKG_PYTHON=$(basename $PKG_PYTHON)

tar -xf $PKG_PYTHON
cd ${PKG_PYTHON%.tar*}

./configure --prefix=/usr   \
            --enable-shared \
            --without-ensurepip

make
make install

cd /sources
rm -rf ${PKG_PYTHON%.tar*}

