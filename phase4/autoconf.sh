#!/usr/bin/env bash
# Autoconf Stage 6
# ~~~~~~~~~~~~~~~~
set -e

cd /sources

eval "$(grep AUTOCONF $PACKAGE_LIST)"
PKG_AUTOCONF=$(basename $PKG_AUTOCONF)

tar -xf $PKG_AUTOCONF
cd ${PKG_AUTOCONF%.tar*}

./configure --prefix=/usr

make

if $RUN_TESTS
then
    set +e
    make check TESTSUITEFLAGS=-j4 &> $TESTLOG_DIR/autoconf.log
    set -e
fi

make install 

cd /sources
rm -rf ${PKG_AUTOCONF%.tar*}

