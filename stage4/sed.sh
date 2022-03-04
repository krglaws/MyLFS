#!/usr/bin/env bash
# Sed Stage 4
# ~~~~~~~~~~~
set -e

cd $LFS/sources

eval "$(grep SED $PACKAGE_LIST)"
PKG_SED=$(basename $PKG_SED)

tar -xf $PKG_SED
cd ${PKG_SED%.tar*}

./configure --prefix=/usr   \
            --host=$LFS_TGT

make
make DESTDIR=$LFS install

cd $LFS/sources
rm -rf ${PKG_SED%.tar*}

