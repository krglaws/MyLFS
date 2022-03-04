#!/usr/bin/env bash
# M4 Stage 4
# ~~~~~~~~~~
set -e

cd $LFS/sources

eval "$(grep M4 $PACKAGE_LIST)"

PKG_M4=$(basename $PKG_M4)

tar -xf $PKG_M4
cd ${PKG_M4%.tar*}

./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)

make
make DESTDIR=$LFS install

cd $LFS/sources
rm -rf ${PKG_M4%.tar*}

