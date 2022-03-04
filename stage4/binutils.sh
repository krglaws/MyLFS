#!/usr/bin/env bash
# Binutils Stage 4
# ~~~~~~~~~~~~~~~~
set -e

cd $LFS/sources

eval "$(grep BINUTILS $PACKAGE_LIST)"
PKG_BINUTILS=$(basename $PKG_BINUTILS)

tar -xf $PKG_BINUTILS
cd ${PKG_BINUTILS%.tar*}

sed '6009s/$add_dir//' -i ltmain.sh

mkdir build
cd build

../configure                   \
    --prefix=/usr              \
    --build=$(../config.guess) \
    --host=$LFS_TGT            \
    --disable-nls              \
    --enable-shared            \
    --disable-werror           \
    --enable-64-bit-bfd

make
make DESTDIR=$LFS install

cd $LFS/sources
rm -rf ${PKG_BINUTILS%.tar*}

