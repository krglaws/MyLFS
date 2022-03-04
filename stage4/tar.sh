#!/usr/bin/env bash
# Tar Stage 4
# ~~~~~~~~~~~
set -e

cd $LFS/sources

eval "$(grep TAR $PACKAGE_LIST)"
PKG_TAR=$(basename $PKG_TAR)

tar -xf $PKG_TAR
cd ${PKG_TAR%.tar*}

./configure --prefix=/usr                     \
            --host=$LFS_TGT                   \
            --build=$(build-aux/config.guess)

make
make DESTDIR=$LFS install

cd $LFS/sources
rm -rf ${PKG_TAR%.tar*}

