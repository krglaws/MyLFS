#!/usr/bin/env bash
# MPFR Stage 6
# ~~~~~~~~~~~~
set -e

cd /sources

eval "$(grep MPFR $PACKAGE_LIST)"
PKG_MPFR=$(basename $PKG_MPFR)

tar -xf $PKG_MPFR
cd ${PKG_MPFR%.tar*}

./configure --prefix=/usr        \
            --disable-static     \
            --enable-thread-safe \
            --docdir=/usr/share/doc/mpfr-4.1.0

make
make html

make check

make install
make install-html

cd /sources
rm -rf ${PKG_MPFR%.tar*}

