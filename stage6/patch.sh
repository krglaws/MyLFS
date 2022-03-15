#!/usr/bin/env bash
# Patch Stage 6
# ~~~~~~~~~~~~~
set -e

cd /sources

eval "$(grep PATCH $PACKAGE_LIST)"
PKG_PATCH=$(basename $PKG_PATCH)

tar -xf $PKG_PATCH
cd ${PKG_PATCH%.tar*}

./configure --prefix=/usr

make

if $RUN_TESTS
then
    set +e
    make check &> $TESTLOG_DIR/patch.log
    set -e
fi

make install

cd /sources
rm -rf ${PKG_PATCH%.tar*}

