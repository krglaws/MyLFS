#!/usr/bin/env bash
# Tar Stage 6
# ~~~~~~~~~~~
set -e

cd /sources

eval "$(grep TAR $PACKAGE_LIST)"
PKG_TAR=$(basename $PKG_TAR)

tar -xf $PKG_TAR
cd ${PKG_TAR%.tar*}

FORCE_UNSAFE_CONFIGURE=1  \
./configure --prefix=/usr

make

make check

make install

make -C doc install-html docdir=/usr/share/doc/tar-1.34

cd /sources
rm -rf ${PKG_TAR%.tar*}

