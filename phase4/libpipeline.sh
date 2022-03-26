#!/usr/bin/env bash
# Libpipeline Stage 6
# ~~~~~~~~~~~~~~~~~~~
set -e

cd /sources

eval "$(grep LIBPIPELINE $PACKAGE_LIST)"
PKG_LIBPIPELINE=$(basename $PKG_LIBPIPELINE)

tar -xf $PKG_LIBPIPELINE
cd ${PKG_LIBPIPELINE%.tar*}

./configure --prefix=/usr

make

if $RUN_TESTS
then
    set +e
    make check &> $TESTLOG_DIR/libpipeline.sh
    set -e
fi

make install

cd /sources
rm -rf ${PKG_LIBPIPELINE%.tar*}

