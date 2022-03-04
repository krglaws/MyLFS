#!/usr/bin/env bash
# Coreutils Stage 4
# ~~~~~~~~~~~~~~~~~
set -e

cd $LFS/sources

eval "$(grep COREUTILS $PACKAGE_LIST)"
PKG_COREUTILS=$(basename $PKG_COREUTILS)
PATCH_COREUTILS=$(basename $PATCH_COREUTILS)

tar -xf $PKG_COREUTILS
cd ${PKG_COREUTILS%.tar*}

patch -p1 < ../$PATCH_COREUTILS

./configure --prefix=/usr                     \
            --host=$LFS_TGT                   \
            --build=$(build-aux/config.guess) \
            --enable-install-program=hostname \
            --enable-no-install-program=kill,uptime

make
make DESTDIR=$LFS install

mv -v $LFS/usr/bin/chroot $LFS/usr/sbin
mkdir -pv $LFS/usr/share/man/man8
mv -v $LFS/usr/share/man/man1/chroot.1 $LFS/usr/share/man/man8/chroot.8
sed -i 's/"1"/"8"/' $LFS/usr/share/man/man8/chroot.8

cd $LFS/sources
rm -rf ${PKG_COREUTILS%.tar*}

