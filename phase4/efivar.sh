#!/usr/bin/env bash
# efivar Stage 6
# ~~~~~~~~~~~~
set -e

cd /sources

eval "$(grep EFIVAR $PACKAGE_LIST)"
PKG_EFIVAR=$(basename $PKG_EFIVAR)

tar -xf $PKG_EFIVAR
cd ${PKG_EFIVAR%.tar*}

sed '/prep :/a\\ttouch prep' -i src/Makefile

make

make install LIBDIR=/usr/lib

cd /sources
rm -rf ${PKG_EFIVAR%.tar*}

