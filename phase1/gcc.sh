# GCC Phase 1
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

../configure                                       \
    --target=$LFS_TGT                              \
    --prefix=$LFS/tools                            \
    --with-glibc-version=2.36                      \
    --with-sysroot=$LFS                            \
    --with-newlib                                  \
    --without-headers                              \
    --disable-nls                                  \
    --disable-shared                               \
    --disable-multilib                             \
    --disable-decimal-float                        \
    --disable-threads                              \
    --disable-libatomic                            \
    --disable-libgomp                              \
    --disable-libquadmath                          \
    --disable-libssp                               \
    --disable-libvtv                               \
    --disable-libstdcxx                            \
    --enable-languages=c,c++

make
make install

cd ..

cat gcc/limitx.h gcc/glimits.h gcc/limity.h > \
  $(dirname $($LFS_TGT-gcc -print-libgcc-file-name))/install-tools/include/limits.h 

