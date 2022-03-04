#!/usr/bin/env bash
# Findutils Stage 4
# ~~~~~~~~~~~~~~~~~
set -e

cd $LFS/sources

eval "$(grep FINDUTILS $PACKAGE_LIST)"
PKG_FINDUTILS=$(basename $PKG_FINDUTILS)

tar -xf $PKG_FINDUTILS
cd ${PKG_FINDUTILS%.tar*}

./configure --prefix=/usr                   \
            --localstatedir=/var/lib/locate \
            --host=$LFS_TGT                 \
            --build=$(build-aux/config.guess)

make
make DESTDIR=$LFS install

cd $LFS/sources
rm -rf ${PKG_FINDUTILS%.tar*}

