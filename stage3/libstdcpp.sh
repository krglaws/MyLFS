#/usr/bin/env bash
set -ex

cd $LFS/sources

# libstdc++
tar -xf gcc-11.2.0.tar.xz
cd gcc-11.2.0

mkdir -v build
cd build

../libstdc++-v3/configure           \
    --host=$LFS_TGT                 \
    --build=$(../config.guess)      \
    --prefix=/usr                   \
    --disable-multilib              \
    --disable-nls                   \
    --disable-libstdcxx-pch         \
    --with-gxx-include-dir=/tools/$LFS_TGT/include/c++/11.2.0

make
make DESTDIR=$LFS install

cd $LFS/sources
rm -rf gcc-11.2.0
