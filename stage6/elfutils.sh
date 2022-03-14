#!/usr/bin/env bash
# Elfutils Stage 6
# ~~~~~~~~~~~~~~~~
set -e

cd /sources

eval "$(grep ELFUTILS $PACKAGE_LIST)"
PKG_ELFUTILS=$(basename $PKG_ELFUTILS)

tar -xf $PKG_ELFUTILS
cd ${PKG_ELFUTILS%.tar*}

./configure --prefix=/usr                \
            --disable-debuginfod         \
            --enable-libdebuginfod=dummy

make

make check

make -C libelf install
install -m644 config/libelf.pc /usr/lib/pkgconfig
rm /usr/lib/libelf.a

cd /sources
rm -rf ${PKG_ELFUTILS%.tar*}

