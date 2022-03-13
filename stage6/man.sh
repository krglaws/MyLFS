#!/usr/bin/env bash
# Man Pages Stage 6
# ~~~~~~~~~~~~~~~~~
set -e

cd /sources

eval "$(grep MAN $PACKAGE_LIST)"
PKG_MAN=$(basename $PKG_MAN)

tar -xf $PKG_MAN
cd ${PKG_MAN%.tar*}

make prefix=/usr install

cd /sources
rm -rf ${PKG_MAN%.tar*}

