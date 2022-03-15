#!/usr/bin/env bash
# Libtool Stage 6
# ~~~~~~~~~~~~~~~
set -e

cd /sources

eval "$(grep LIBTOOL $PACKAGE_LIST)"
PKG_LIBTOOL=$(basename $PKG_LIBTOOL)

tar -xf $PKG_LIBTOOL
cd ${PKG_LIBTOOL%.tar*}

./configure --prefix=/usr

make

if $RUN_TESTS
then
    set +e
    make check TESTSUITEFLAGS=-j4 &> $TESTLOG_DIR/libtool.log
    set -e
fi

make install

rm -f /usr/lib/libltdl.a

cd /sources
rm -rf ${PKG_LIBTOOL%.tar*}

