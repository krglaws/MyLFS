#!/usr/bin/env bash
# Gawk Stage 4
# ~~~~~~~~~~~~
set -e

cd $LFS/sources

eval "$(grep GAWK $PACKAGE_LIST)"
PKG_GAWK=$(basename $PKG_GAWK)

tar -xf $PKG_GAWK
cd ${PKG_GAWK%.tar*}

sed -i 's/extras//' Makefile.in

./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)

make
make DESTDIR=$LFS install

cd $LFS/sources
rm -rf ${PKG_GAWK%.tar*}

