#!/usr/bin/env bash
# Flex Stage 6
# ~~~~~~~~~~~~
set -e

cd /sources

eval "$(grep FLEX $PACKAGE_LIST)"
PKG_FLEX=$(basename $PKG_FLEX)

tar -xf $PKG_FLEX
cd ${PKG_FLEX%.tar*}

./configure --prefix=/usr \
            --docdir=/usr/share/doc/flex-2.6.4 \
            --disable-static

make

make check

make install

ln -s flex /usr/bin/lex

cd /sources
rm -rf ${PKG_FLEX%.tar*}

