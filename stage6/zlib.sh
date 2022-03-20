#!/usr/bin/env bash
# Zlib Stage 6
# ~~~~~~~~~~~~
set -e

cd /sources

eval "$(grep ZLIB $PACKAGE_LIST)"
PKG_ZLIB=$(basename $PKG_ZLIB)

tar -xf $PKG_ZLIB
cd ${PKG_ZLIB%.tar*}

./configure --prefix=/usr

make

if $RUN_TESTS
then
    set +e
    make check &> $TESTLOG_DIR/zlib.log
    set -e
fi

make install

rm -f /usr/lib/libz.a

cd /sources
rm -rf ${PKG_ZLIB%.tar*}