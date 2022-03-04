#!/usr/bin/env bash
# Diffutils Stage 4
# ~~~~~~~~~~~~~~~~~
set -e

cd $LFS/sources

eval "$(grep DIFFUTILS $PACKAGE_LIST)"
PKG_DIFFUTILS=$(basename $PKG_DIFFUTILS)

tar -xf $PKG_DIFFUTILS
cd ${PKG_DIFFUTILS%.tar*}

./configure --prefix=/usr --host=$LFS_TGT

make
make DESTDIR=$LFS install

cd $LFS/sources
rm -rf ${PKG_DIFFUTILS%.tar*}

