#!/usr/bin/env bash
# Xz Stage 4
# ~~~~~~~~~~
set -e

cd $LFS/sources

eval "$(grep XZ $PACKAGE_LIST)"
PKG_XZ=$(basename $PKG_XZ)

tar -xf $PKG_XZ
cd ${PKG_XZ%.tar*}

./configure --prefix=/usr                     \
            --host=$LFS_TGT                   \
            --build=$(build-aux/config.guess) \
            --disable-static                  \
            --docdir=/usr/share/doc/xz-5.2.5

make
make DESTDIR=$LFS install

cd $LFS/sources
rm -rf ${PKG_XZ%.tar*}

