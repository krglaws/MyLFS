# GCC Phase 2
PKG_MPFR=$(basename $PKG_MPFR)
PKG_GMP=$(basename $PKG_GMP)
PKG_MPC=$(basename $PKG_MPC)

tar -xf ../$PKG_MPFR
mv ${PKG_MPFR%.tar*} mpfr

tar -xf ../$PKG_GMP
mv ${PKG_GMP%.tar*} gmp

tar -xf ../$PKG_MPC
mv ${PKG_MPC%.tar*} mpc

case $(uname -m) in
  x86_64)
    sed -e '/m64=/s/lib64/lib/' -i.orig gcc/config/i386/t-linux64
  ;;
esac

mkdir build
cd build

mkdir -p $LFS_TGT/libgcc
ln -s ../../../libgcc/gthr-posix.h $LFS_TGT/libgcc/gthr-default.h

../configure                                       \
    --build=$(../config.guess)                     \
    --host=$LFS_TGT                                \
    --prefix=/usr                                  \
    CC_FOR_TARGET=$LFS_TGT-gcc                     \
    --with-build-sysroot=$LFS                      \
    --enable-initfini-array                        \
    --disable-nls                                  \
    --disable-multilib                             \
    --disable-decimal-float                        \
    --disable-libatomic                            \
    --disable-libgomp                              \
    --disable-libquadmath                          \
    --disable-libssp                               \
    --disable-libvtv                               \
    --disable-libstdcxx                            \
    --enable-languages=c,c++

make
make DESTDIR=$LFS install

ln -s gcc $LFS/usr/bin/cc

