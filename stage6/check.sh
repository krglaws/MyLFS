#!/usr/bin/env bash
# Check Stage 6
# ~~~~~~~~~~~~~
set -e

cd /sources

eval "$(grep CHECK $PACKAGE_LIST)"
PKG_CHECK=$(basename $PKG_CHECK)

tar -xf $PKG_CHECK
cd ${PKG_CHECK%.tar*}

./configure --prefix=/usr --disable-static

make

make check

make docdir=/usr/share/doc/check-0.15.2 install

cd /sources
rm -rf ${PKG_CHECK%.tar*}

