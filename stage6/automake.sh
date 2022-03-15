#!/usr/bin/env bash
# Automake Stage 6
# ~~~~~~~~~~~~~~~~
set -e

cd /sources

eval "$(grep AUTOMAKE $PACKAGE_LIST)"
PKG_AUTOMAKE=$(basename $PKG_AUTOMAKE)

tar -xf $PKG_AUTOMAKE
cd ${PKG_AUTOMAKE%.tar*}

./configure --prefix=/usr --docdir=/usr/share/doc/automake-1.16.5

make

if $RUN_TESTS
then
    set +e
    make -j4 check &> TESTLOG_DIR/automake.log
    set -e
fi

make install

cd /sources
rm -rf ${PKG_AUTOMAKE%.tar*}

