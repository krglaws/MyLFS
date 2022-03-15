#!/usr/bin/env bash
# Man Pages Stage 6
# ~~~~~~~~~~~~~~~~~
set -e

cd /sources

eval "$(grep MANPAGES $PACKAGE_LIST)"
PKG_MANPAGES=$(basename $PKG_MANPAGES)

tar -xf $PKG_MANPAGES
cd ${PKG_MANPAGES%.tar*}

make prefix=/usr install

cd /sources
rm -rf ${PKG_MANPAGES%.tar*}

