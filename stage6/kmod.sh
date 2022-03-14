#!/usr/bin/env bash
# Kmod Stage 6
# ~~~~~~~~~~~~
set -e

cd /sources

eval "$(grep KMOD $PACKAGE_LIST)"
PKG_KMOD=$(basename $PKG_KMOD)

tar -xf $PKG_KMOD
cd ${PKG_KMOD%.tar*}

./configure --prefix=/usr          \
            --sysconfdir=/etc      \
            --with-openssl         \
            --with-xz              \
            --with-zstd            \
            --with-zlib

make

make install

for target in depmod insmod modinfo modprobe rmmod; do
  ln -sf ../bin/kmod /usr/sbin/$target
done

ln -sf kmod /usr/bin/lsmod

cd /sources
rm -rf ${PKG_KMOD%.tar*}

