#!/usr/bin/env bash
# Bash Stage 4
# ~~~~~~~~~~~~
set -e

cd $LFS/sources

eval "$(grep BASH $PACKAGE_LIST)"
PKG_BASH=$(basename $PKG_BASH)

tar -xf $PKG_BASH
cd ${PKG_BASH%.tar*}

./configure --prefix=/usr                   \
            --build=$(support/config.guess) \
            --host=$LFS_TGT                 \
            --without-bash-malloc

make
make DESTDIR=$LFS install
ln -sv bash $LFS/bin/sh

cd $LFS/sources
rm -rf ${PKG_BASH%.tar*}

