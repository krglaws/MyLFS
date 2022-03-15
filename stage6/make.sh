#!/usr/bin/env bash
# Make Stage 6
# ~~~~~~~~~~~~
set -e

cd /sources

eval "$(grep MAKE $PACKAGE_LIST)"
PKG_MAKE=$(basename $PKG_MAKE)

tar -xf $PKG_MAKE
cd ${PKG_MAKE%.tar*}

./configure --prefix=/usr

make

if $RUN_TESTS
then
    set +e
    make check &> $TESTLOG_DIR/make.log
    set -e
fi

make install

cd /sources
rm -rf ${PKG_MAKE%.tar*}

