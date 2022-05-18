# Binutils Phase 2
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

