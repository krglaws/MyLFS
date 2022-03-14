#!/usr/bin/env bash
# Eudev Stage 6
# ~~~~~~~~~~~~~
set -e

cd /sources

eval "$(grep EUDEV $PACKAGE_LIST)"
PKG_EUDEV=$(basename $PKG_EUDEV)

tar -xf $PKG_EUDEV
cd ${PKG_EUDEV%.tar*}

./configure --prefix=/usr           \
            --bindir=/usr/sbin      \
            --sysconfdir=/etc       \
            --enable-manpages       \
            --disable-static

make

mkdir -pv /usr/lib/udev/rules.d
mkdir -pv /etc/udev/rules.d

make check

make install

tar -xf ../udev-lfs-20171102.tar.xz
make -f udev-lfs-20171102/Makefile.lfs install

udevadm hwdb --update

cd /sources
rm -rf ${PKG_EUDEV%.tar*}

