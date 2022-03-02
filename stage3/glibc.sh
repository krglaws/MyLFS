#!/usr/bin/env bash
# Glibc pass 1
# ~~~~~~~~~~~~
set -e

cd $LFS/sources

eval "$(grep "PKG_GLIBC\|PATCH_GLIBC" $PACKAGE_LIST)"
curl -LO $PKG_GLIBC -LO $PATCH_GLIBC

PKG_GLIBC=$(basename $PKG_GLIBC)
PATCH_GLIBC=$(basename $PATCH_GLIBC)

tar -xf $PKG_GLIBC
cd ${PKG_GLIBC%.tar*}

case $(uname -m) in
    i?86)
        ln -sfv ld-linux.so.2 $LFS/lib/ld-lsb.so.3
    ;;
    x86_64)
        ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS/lib64
        ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS/lib64/ld-lsb-x86-64.so.3
    ;;
esac

patch -Np1 -i ../$PATCH_GLIBC

mkdir build
cd build

echo "rootsbindir=/usr/sbin" > configparms

../configure                             \
      --prefix=/usr                      \
      --host=$LFS_TGT                    \
      --build=$(../scripts/config.guess) \
      --enable-kernel=3.2                \
      --with-headers=$LFS/usr/include    \
      libc_cv_slibdir=/usr/lib

make
make DESTDIR=$LFS install

sed '/RTLDLIST=/s@/usr@@g' -i $LFS/usr/bin/ldd

# check that everything is good
echo 'int main(){}' > dummy.c
$LFS_TGT-gcc dummy.c
OUTPUT=$(readelf -l a.out | grep '/ld-linux') 
EXPECTED='[Requesting program interpreter: /lib64/ld-linux-x86-64.so.2]'
if [[ "$OUTPUT" != *"${EXPECTED}"* ]]
then
    echo "ERROR: OUTPUT does not contain expected value.\n" \
         "OUTPUT=$OUTPUT\n" \
         "EXPECTED=$EXPECTED"
    exit -1
fi
rm dummy.c a.out

$LFS/tools/libexec/gcc/$LFS_TGT/11.2.0/install-tools/mkheaders

cd $LFS/sources
rm -rf ${PKG_GLIBC%.tar*} $PKG_GLIBC $PATCH_GLIBC

