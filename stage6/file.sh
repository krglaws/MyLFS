#!/usr/bin/env bash
# File Stage 6
# ~~~~~~~~~~~~
set -e

cd /sources

eval "$(grep FILE $PACKAGE_LIST)"
PKG_FILE=$(basename $PKG_FILE)

tar -xf $PKG_FILE
cd ${PKG_FILE%.tar*}

./configure --prefix=/usr

make

if $RUN_TESTS
then
    set +e
    make check &> $TESTLOG_DIR/file.log
    set -e
fi

make install

cd /sources
rm -rf ${PKG_FILE%.tar*}

