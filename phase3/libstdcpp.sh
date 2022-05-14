# Libstdc++ Phase 3
ln -s gthr-posix.h libgcc/gthr-default.h

mkdir build
cd build

../libstdc++-v3/configure           \
    CXXFLAGS="-g -O2 -D_GNU_SOURCE" \
    --prefix=/usr                   \
    --disable-multilib              \
    --disable-nls                   \
    --host=$LFS_TGT                 \
    --disable-libstdcxx-pch        

make
make install

