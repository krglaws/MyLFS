#!/usr/bin/env bash
# Patch Stage 4
# ~~~~~~~~~~~~~
set -e

cd $LFS/sources

eval "$(grep PATCH $PACKAGE_LIST)"
PKG_PATCH=$(basename $PKG_PATCH)

tar -xf $PKG_PATCH
cd ${PKG_PATCH%.tar*}

./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)

make
make DESTDIR=$LFS install

cd $LFS/sources
rm -rf ${PKG_PATCH%.tar*}

