#!/usr/bin/env bash
# Man-DB Stage 6
# ~~~~~~~~~~~~~~
set -e

cd /sources

eval "$(grep MANDB $PACKAGE_LIST)"
PKG_MANDB=$(basename $PKG_MANDB)

tar -xf $PKG_MANDB
cd ${PKG_MANDB%.tar*}

./configure --prefix=/usr                         \
            --docdir=/usr/share/doc/man-db-2.10.1 \
            --sysconfdir=/etc                     \
            --disable-setuid                      \
            --enable-cache-owner=bin              \
            --with-browser=/usr/bin/lynx          \
            --with-vgrind=/usr/bin/vgrind         \
            --with-grap=/usr/bin/grap             \
            --with-systemdtmpfilesdir=            \
            --with-systemdsystemunitdir=

make

make check

make install

cd /sources
rm -rf ${PKG_MANDB%.tar*}

