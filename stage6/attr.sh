#!/usr/bin/env bash
# Attr Stage 6
# ~~~~~~~~~~~~
set -e

cd /sources

eval "$(grep ATTR $PACKAGE_LIST)"
PKG_ATTR=$(basename $PKG_ATTR)

tar -xf $PKG_ATTR
cd ${PKG_ATTR%.tar*}

./configure --prefix=/usr     \
            --disable-static  \
            --sysconfdir=/etc \
            --docdir=/usr/share/doc/attr-2.5.1

make
make check

make install

cd /sources
rm -rf ${PKG_ATTR%.tar*}

