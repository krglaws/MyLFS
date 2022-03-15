#!/usr/bin/env bash
# Bc Stage 6
# ~~~~~~~~~~
set -e

cd /sources

eval "$(grep BC $PACKAGE_LIST)"
PKG_BC=$(basename $PKG_BC)

tar -xf $PKG_BC
cd ${PKG_BC%.tar*}

CC=gcc ./configure --prefix=/usr -G -O3

make

if $RUN_TESTS
then
    set +e
    make test &> $TESTLOG_DIR/bc.log
    set -e
fi

make install

cd /sources
rm -rf ${PKG_BC%.tar*}

