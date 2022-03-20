#!/usr/bin/env bash
# Texinfo Stage 6
# ~~~~~~~~~~~~~~~
set -e

cd /sources

eval "$(grep TEXINFO $PACKAGE_LIST)"
PKG_TEXINFO=$(basename $PKG_TEXINFO)

tar -xf $PKG_TEXINFO
cd ${PKG_TEXINFO%.tar*}

./configure --prefix=/usr

sed -e 's/__attribute_nonnull__/__nonnull/' \
    -i gnulib/lib/malloc/dynarray-skeleton.c

make

if $RUN_TESTS
then
    set +e
    make check &> $TESTLOG_DIR/texinfo.log
    set -e
fi

make install

cd /sources
rm -rf ${PKG_TEXINFO%.tar*}
