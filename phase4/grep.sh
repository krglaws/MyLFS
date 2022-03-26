#!/usr/bin/env bash
# Grep Stage 6
# ~~~~~~~~~~~~
set -e

cd /sources

eval "$(grep GREP $PACKAGE_LIST)"
PKG_GREP=$(basename $PKG_GREP)

tar -xf $PKG_GREP
cd ${PKG_GREP%.tar*}

./configure --prefix=/usr

make

if $RUN_TESTS
then
    set +e
    make check &> $TESTLOG_DIR/grep.log
    set -e
fi

make install

cd /sources
rm -rf ${PKG_GREP%.tar*}

