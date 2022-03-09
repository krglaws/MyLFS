#!/usr/bin/env bash
# Libstdc++ Stage 5
# ~~~~~~~~~~~~~~~~~
set -e

cd /sources

eval "$(grep PKG_GCC $PACKAGE_LIST)"
PKG_GCC=$(basename $PKG_GCC)

tar -xf $PKG_GCC
cd ${PKG_GCC%.tar*}

ln -s gthr-posix.h libgcc/gthr-default.h

mkdir build
cd build

../libstdc++-v3/configure           \
    CXXFLAGS="-g -O2 -D_GNU_SOURCE" \
    --host=$LFS_TGT                 \
    --prefix=/usr                   \
    --disable-multilib              \
    --disable-nls                   \
    --disable-libstdcxx-pch         \

make
make install

cd /sources
rm -rf ${PKG_GCC%.tar*}

