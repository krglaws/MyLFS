#!/usr/bin/env bash
# Gperf Stage 6
# ~~~~~~~~~~~~~
set -e

cd /sources

eval "$(grep GPERF $PACKAGE_LIST)"
PKG_GPERF=$(basename $PKG_GPERF)

tar -xf $PKG_GPERF
cd ${PKG_GPERF%.tar*}

./configure --prefix=/usr --docdir=/usr/share/doc/gperf-3.1

make

if $RUN_TESTS
then
    set +e
    make -j1 check &> $TESTLOG_DIR/gperf.log
    set -e
fi

make install

cd /sources
rm -rf ${PKG_GPERF%.tar*}

