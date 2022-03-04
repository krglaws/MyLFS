#!/usr/bin/env bash
# Linux API headers
# ~~~~~~~~~~~~~~~~~
set -e

cd $LFS/sources

eval "$(grep PKG_LINUX $PACKAGE_LIST)"
PKG_LINUX=$(basename $PKG_LINUX)

tar -xf $PKG_LINUX
cd ${PKG_LINUX%.tar*}

make mrproper
make headers

find usr/include -name '.*' -delete
rm usr/include/Makefile
cp -rv usr/include $LFS/usr

cd $LFS/sources
rm -rf ${PKG_LINUX%.tar*}

