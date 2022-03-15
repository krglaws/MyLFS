#!/usr/bin/env bash
# Diffutils Stage 6
# ~~~~~~~~~~~~~~~~~
set -e

cd /sources

eval "$(grep DIFFUTILS $PACKAGE_LIST)"
PKG_DIFFUTILS=$(basename $PKG_DIFFUTILS)

tar -xf $PKG_DIFFUTILS
cd ${PKG_DIFFUTILS%.tar*}

./configure --prefix=/usr

make

if $RUN_TESTS
then
    set +e
    make check &> $TESTLOG_DIR/diffutils.log
    set -e
fi

make install

cd /sources
rm -rf ${PKG_DIFFUTILS%.tar*}

