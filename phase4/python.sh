#!/usr/bin/env bash
# Python Stage 6
# ~~~~~~~~~~~~~~
set -e

cd /sources

eval "$(grep PYTHON $PACKAGE_LIST)"
PKG_PYTHON=$(basename $PKG_PYTHON)

tar -xf $PKG_PYTHON
cd ${PKG_PYTHON%.tar*}

./configure --prefix=/usr        \
            --enable-shared      \
            --with-system-expat  \
            --with-system-ffi    \
            --with-ensurepip=yes \
            --enable-optimizations

make

make install

install -dm755 /usr/share/doc/python-3.10.2/html

tar --strip-components=1  \
    --no-same-owner       \
    --no-same-permissions \
    -C /usr/share/doc/python-3.10.2/html \
    -xvf ../python-3.10.2-docs-html.tar.bz2

cd /sources
rm -rf ${PKG_PYTHON%.tar*}

