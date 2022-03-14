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

make check TESTSUITEFLAGS=-j4

make install

rm -f /usr/lib/libltdl.a

cd /sources
rm -rf ${PKG_LIBTOOL%.tar*}

