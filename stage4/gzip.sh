#!/usr/bin/env bash
# Gzip Stage 4
set -e

cd $LFS/sources

eval "$(grep GZIP $PACKAGE_LIST)"
PKG_GZIP=$(basename $PKG_GZIP)

tar -xf $PKG_GZIP
cd ${PKG_GZIP%.tar*}

./configure --prefix=/usr --host=$LFS_TGT

make
make DESTDIR=$LFS install

cd $LFS/sources
rm -rf ${PKG_GZIP%.tar*}

