#!/usr/bin/env bash
# File Stage 4
# ~~~~~~~~~~~~
set -e

cd $LFS/sources

eval "$(grep FILE $PACKAGE_LIST)"
PKG_FILE=$(basename $PKG_FILE)

tar -xf $PKG_FILE
cd ${PKG_FILE%.tar*}

mkdir build
pushd build
../configure --disable-bzlib      \
             --disable-libseccomp \
             --disable-xzlib      \
             --disable-zlib
make
popd

./configure --prefix=/usr --host=$LFS_TGT --build=$(./config.guess)
make FILE_COMPILE=$(pwd)/build/src/file
make DESTDIR=$LFS install

cd $LFS/sources
rm -rf ${PKG_FILE%.tar*}
