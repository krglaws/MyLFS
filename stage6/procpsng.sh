#!/usr/bin/env bash
# Procps-ng Stage 6
# ~~~~~~~~~~~~~~~~~
set -e

cd /sources

eval "$(grep PROCPS $PACKAGE_LIST)"
PKG_PROCPS=$(basename $PKG_PROCPS)

tar -xf $PKG_PROCPS
cd ${PKG_PROCPS%.tar*}

./configure --prefix=/usr                            \
            --docdir=/usr/share/doc/procps-ng-3.3.17 \
            --disable-static                         \
            --disable-kill

make

make check

make install

cd /sources
rm -rf ${PKG_PROCPS%.tar*}

