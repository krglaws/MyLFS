#!/usr/bin/env bash
# Make Stage 4
# ~~~~~~~~~~~~
set -e

cd $LFS/sources

eval "$(grep MAKE $PACKAGE_LIST)"
PKG_MAKE=$(basename $PKG_MAKE)

tar -xf $PKG_MAKE
cd ${PKG_MAKE%.tar*}

./configure --prefix=/usr   \
            --without-guile \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)

make
make DESTDIR=$LFS install

cd $LFS/sources
rm -rf ${PKG_MAKE%.tar*}

