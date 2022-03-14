#!/usr/bin/env bash
# Kbd Stage 6
# ~~~~~~~~~~~
set -e

cd /sources

eval "$(grep KBD $PACKAGE_LIST)"
PKG_KBD=$(basename $PKG_KBD)
PATCH_KBD=$(basename $PATCH_KBD)

tar -xf $PKG_KBD
cd ${PKG_KBD%.tar*}

patch -Np1 -i ../kbd-2.4.0-backspace-1.patch

sed -i '/RESIZECONS_PROGS=/s/yes/no/' configure
sed -i 's/resizecons.8 //' docs/man/man8/Makefile.in

./configure --prefix=/usr --disable-vlock

make

make check

make install

mkdir -pv           /usr/share/doc/kbd-2.4.0
cp -R -v docs/doc/* /usr/share/doc/kbd-2.4.0

cd /sources
rm -rf ${PKG_KBD%.tar*}

