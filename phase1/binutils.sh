# Bintuils Phase 1

mkdir build
cd build

../configure \
    --prefix=$LFS/tools \
    --with-sysroot=$LFS \
    --target=$LFS_TGT \
    --disable-nls \
    --enable-gprofng=no \
    --disable-werror

make

make install

