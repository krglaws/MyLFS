#!/usr/bin/env bash
# Expat Stage 6
# ~~~~~~~~~~~~~
set -e

cd /sources

eval "$(grep EXPAT $PACKAGE_LIST)"
PKG_EXPAT=$(basename $PKG_EXPAT)

tar -xf $PKG_EXPAT
cd ${PKG_EXPAT%.tar*}

./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/expat-2.4.6

make

make check

make install

install -m644 doc/*.{html,css} /usr/share/doc/expat-2.4.6

cd /sources
rm -rf ${PKG_EXPAT%.tar*}

