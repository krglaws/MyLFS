#!/usr/bin/env bash
# Gzip Stage 6
# ~~~~~~~~~~~~
set -e

cd /sources

eval "$(grep GZIP $PACKAGE_LIST)"
PKG_GZIP=$(basename $PKG_GZIP)

tar -xf $PKG_GZIP
cd ${PKG_GZIP%.tar*}

./configure --prefix=/usr

make

if $RUN_TESTS
then
    set +e
    make check &> $TESTLOG_DIR/gzip.log
    set -e
fi

make install

cd /sources
rm -rf ${PKG_GZIP%.tar*}

