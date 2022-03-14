#!/usr/bin/env bash
# Intltool Stage 6
# ~~~~~~~~~~~~~~~~
set -e

cd /sources

eval "$(grep INTLTOOL $PACKAGE_LIST)"
PKG_INTLTOOL=$(basename $PKG_INTLTOOL)

tar -xf $PKG_INTLTOOL
cd ${PKG_INTLTOOL%.tar*}

sed -i 's:\\\${:\\\$\\{:' intltool-update.in

./configure --prefix=/usr

make

make check

make install
install -Dm644 doc/I18N-HOWTO /usr/share/doc/intltool-0.51.0/I18N-HOWTO

cd /sources
rm -rf ${PKG_INTLTOOL%.tar*}

