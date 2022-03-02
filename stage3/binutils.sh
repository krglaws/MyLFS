#!/usr/bin/env bash
# Binutils pass 1
# ~~~~~~~~~~~~~~~
set -e

cd $LFS/sources

eval "$(grep "PKG_BINUTILS\|PATCH_BINUTILS" $PACKAGE_LIST)"
curl -LO $PKG_BINUTILS -LO $PATCH_BINUTILS

PKG_BINUTILS=$(basename $PKG_BINUTILS)
PATCH_BINUTILS=$(basename $PATCH_BINUTILS)

tar -xf $PKG_BINUTILS
cd ${PKG_BINUTILS%.tar*}

patch -p1 < ../$PATCH_BINUTILS

mkdir -v build
cd build

D1=$(date +%s)

../configure \
    --prefix=$LFS/tools \
    --with-sysroot=$LFS \
    --target=$LFS_TGT \
    --disable-nls \
    --disable-werror

# use one thread to ensure consistent SBU calculation
make -j1
make install -j1

D2=$(date +%s)
echo "1 SBU == $((D2-D1)) seconds."

cd $LFS/sources
rm -rf ${PKG_BINUTILS%.tar*} $PKG_BINUTILS $PATCH_BINUTILS

