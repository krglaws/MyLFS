#/usr/bin/env bash
set -ex

cd $LFS/sources

# Binutils-2.37 pass 1
tar -xf binutils-2.37.tar.xz
cd binutils-2.37
patch -p1 < ../binutils-2.37-upstream_fix-1.patch

mkdir -v build
cd build

../configure \
	--prefix=$LFS/tools \
	--with-sysroot=$LFS \
	--target=$LFS_TGT \
	--disable-nls \
	--disable-werror

make
make install -j1

cd $LFS/sources
rm -rf binutils-2.37
