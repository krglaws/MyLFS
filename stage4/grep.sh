#!/usr/bin/env bash
# Grep Stage 4
# ~~~~~~~~~~~~
set -e

cd $LFS/sources

eval "$(grep GREP $PACKAGE_LIST)"
PKG_GREP=$(basename $PKG_GREP)

tar -xf $PKG_GREP
cd ${PKG_GREP%.tar*}

./configure --prefix=/usr   \
            --host=$LFS_TGT
make
make DESTDIR=$LFS install

cd $LFS/sources
rm -rf ${PKG_GREP%.tar*}

