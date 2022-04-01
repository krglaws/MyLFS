#!/usr/bin/env bash
# LINUX Phase 4
# ~~~~~~~~~~~~~
set -e

cd /sources

eval "$(grep LINUX $PACKAGE_LIST)"
PKG_LINUX=$(basename $PKG_LINUX)

tar -xf $PKG_LINUX
cd ${PKG_LINUX%.tar*}

make mrproper

cp /boot/config-5.16.9 ./.config

make

make modules_install

cp arch/x86_64/boot/bzImage /boot/vmlinuz-5.16.9-lfs-11.1

cp System.map /boot/System.map-5.16.9

install -d /usr/share/doc/linux-5.16.9
cp -r Documentation/* /usr/share/doc/linux-5.16.9

cd /sources
rm -rf ${PKG_LINUX%.tar*}

