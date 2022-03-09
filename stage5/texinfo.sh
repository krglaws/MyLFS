#!/usr/bin/env bash
# Texinfo Stage 5
# ~~~~~~~~~~~~~~~
set -e

cd /sources

eval "$(grep TEXINFO $PACKAGE_LIST)"
PKG_TEXINFO=$(basename $PKG_TEXINFO)

tar -xf $PKG_TEXINFO
cd ${PKG_TEXINFO%.tar*}

sed -e 's/__attribute_nonnull__/__nonnull/' \
    -i gnulib/lib/malloc/dynarray-skeleton.c

./configure --prefix=/usr

make
make install

cd /sources
rm -rf ${PKG_TEXINFO%.tar*}
